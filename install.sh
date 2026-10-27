#!/bin/bash
#
# install.sh — deploy this repo's config/ tree into ~/.config
#
# Design notes (why it works the way it does):
#
#   * COPY, not symlink. Omarchy's `omarchy-refresh-config` runs `cp -f` and
#     therefore WRITES THROUGH symlinks: it would silently overwrite the files
#     in this repo instead of replacing the links. Verified against
#     ~/.local/share/omarchy/bin/omarchy-refresh-config on Omarchy 3.8.2.
#     Copying keeps this repo immune to refresh/reinstall.
#
#   * Backups first, always. Every file we are about to overwrite is saved as
#     <target>.bak.<unixtime> before being touched. Nothing is deleted.
#
#   * Symlinks are rebuilt, not copied. Three files in config/ are symlinks into
#     ~/.config/omarchy/current/theme/, which Omarchy regenerates on every theme
#     change. We recreate them so the theme keeps following automatically.
#
#   * No sudo. This only writes inside $HOME. Package installation is a separate,
#     human-reviewed step; see README.md.
#
#   * Symlink targets are rewritten. The three theme-following symlinks in
#     config/ point at an absolute home path recorded at capture time; those are
#     rewritten to the current user's $HOME so they keep working on a new machine.
#     File *contents* are deployed verbatim.
#
# Usage:
#   ./install.sh                              # deploy
#   ./install.sh --dry-run                    # show what would change, touch nothing
#   ./install.sh --wallpapers                 # also install wallpapers for the current theme
#   ./install.sh --wallpapers=<theme>         # also install wallpapers for one theme
#   ./install.sh --wallpapers=all             # also install every theme in the manifest
#
# --wallpapers is off by default: without it the script never touches the network.
# `--dry-run --wallpapers` prints the plan but fetches nothing and writes nothing.

set -euo pipefail

readonly REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SRC_CONFIG="$REPO_DIR/config"
readonly DEST_CONFIG="$HOME/.config"

# The home directory this repo was captured on.
#
# It defaults to $HOME rather than a hard-coded username, which is correct because
# the repo is meant to be cloned into $HOME/Projects/omarchy-NTE — so on a normal
# install captured home == current home and no rewriting happens at all.
#
# Override it only when the repo lives somewhere unusual, e.g.:
#   CAPTURED_HOME=/home/alice ./install.sh
# Symlink targets inside config/ do reference the capture-time home and are always
# rewritten to $HOME.
readonly CAPTURED_HOME="${CAPTURED_HOME:-$HOME}"

# Empty = don't touch wallpapers at all (default). "__current__" = resolve from
# Omarchy's theme.name at install time; otherwise the literal theme name, or "all".
DRY_RUN=false
WALLPAPERS=""
# Set only for a usage-level wallpaper error (unknown theme). Network/checksum
# failures stay warnings: the config deployment itself already succeeded.
wallpaper_usage_error=false

# Where the wallpaper manifest and images live. Override for local testing:
#   WALLPAPERS_BASE=http://127.0.0.1:8765 ./install.sh --wallpapers=catppuccin
readonly WALLPAPERS_BASE="${WALLPAPERS_BASE:-https://raw.githubusercontent.com/CAI991108/omarchy-NTE-wallpaper/main}"

# ── repo → deploy path mapping ────────────────────────────────────────────────
# A few captured files cannot keep their on-disk name: git and shell scripts are
# happier without spaces, but Omarchy expects the original name. Keys and values
# are paths relative to config/.
declare -A PATH_OVERRIDES=(
  # The active catppuccin wallpaper has a space in its name. The repo stores it
  # with a hyphen so it stays shell-friendly, but ~/.config/omarchy/current/
  # background points at the spaced name, so deploy it back with the space.
  ["omarchy/backgrounds/catppuccin/nanally-wallpaper.jpeg"]="omarchy/backgrounds/catppuccin/nanally wallpaper.jpeg"
)

# ── output helpers ────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RESET=$'\e[0m'; C_DIM=$'\e[2m'; C_GREEN=$'\e[32m'
  C_YELLOW=$'\e[33m'; C_CYAN=$'\e[36m'; C_RED=$'\e[31m'
else
  C_RESET=""; C_DIM=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_RED=""
fi

info()  { printf '%s\n' "$*"; }
dim()   { printf '%s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
ok()    { printf '%s  ✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s  !%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
step()  { printf '\n%s==>%s %s\n' "$C_CYAN" "$C_RESET" "$*"; }
die()   { printf '%sERROR:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# ── arguments ─────────────────────────────────────────────────────────────────
# Keep both flags order-independent and reject anything else, so a typo can't
# silently deploy without the wallpapers the user asked for.
while (( $# > 0 )); do
  case "$1" in
    --dry-run)      DRY_RUN=true ;;
    --wallpapers)   WALLPAPERS="__current__" ;;
    --wallpapers=*)
      WALLPAPERS="${1#--wallpapers=}"
      [[ -z $WALLPAPERS ]] && die "--wallpapers= 后面要跟主题名或 all"
      ;;
    *)              die "未知参数: $1（支持 --dry-run 和 --wallpapers[=<theme>|all]）" ;;
  esac
  shift
done

# Run a command, or just print it in dry-run mode.
run() {
  if $DRY_RUN; then
    printf '%s    would run:%s %s\n' "$C_DIM" "$C_RESET" "$*"
  else
    "$@"
  fi
}

# Rewrite a symlink target to an absolute path under the current $HOME.
#
# The three theme-following symlinks in config/ are stored as "$HOME/.config/..."
# so the repo never records a real username. On deploy they become absolute, which
# is what a symlink needs in order to resolve. Older captures may instead hold a
# literal /home/<user> path; both forms are handled.
rewrite_home() {
  local text="$1"
  case "$text" in
    '$HOME'*)                 printf '%s' "$HOME${text#\$HOME}" ;;
    '~'*)                     printf '%s' "$HOME${text#\~}" ;;
    "$CAPTURED_HOME"*)        printf '%s' "$HOME${text#"$CAPTURED_HOME"}" ;;
    /home/*/*|/Users/*/*)     printf '%s' "$HOME/${text#/*/*/}" ;;
    /home/*|/Users/*)         printf '%s' "$HOME" ;;
    /root*)                   printf '%s' "$HOME${text#/root}" ;;
    *)                        printf '%s' "$text" ;;
  esac
}

# Resolve the active Omarchy theme to a backgrounds/ directory name.
#
# 3.8.2 writes the title-cased name to ~/.config/omarchy/current/theme.name
# ("Catppuccin"); 4.x moved that state under ~/.local/state/omarchy/. Backgrounds
# directories are lowercase with hyphens, so normalise the name to that shape.
current_theme() {
  local file name
  for file in \
    "$HOME/.config/omarchy/current/theme.name" \
    "$HOME/.local/state/omarchy/current/theme.name" \
    "$HOME/.local/state/omarchy/theme.name"; do
    [[ -f $file ]] || continue
    name="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$file" \
      | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
    [[ -n $name ]] && { printf '%s\n' "$name"; return 0; }
  done
  if command -v omarchy >/dev/null 2>&1; then
    name="$(omarchy theme current 2>/dev/null | head -n1 \
      | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
      | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
    [[ -n $name ]] && { printf '%s\n' "$name"; return 0; }
  fi
  return 1
}


# ── preflight ─────────────────────────────────────────────────────────────────
[[ -d $SRC_CONFIG ]] || die "找不到 $SRC_CONFIG —— 请在仓库根目录运行本脚本。"

step "omarchy-NTE 配置部署"
info "  仓库:   $REPO_DIR"
info "  源:     $SRC_CONFIG/"
info "  目标:   $DEST_CONFIG/"
info "  捕获时的家目录: $CAPTURED_HOME  →  当前: $HOME"
$DRY_RUN && warn "DRY-RUN 模式：只显示将要做的改动，不会写入任何文件。"

if [[ $CAPTURED_HOME != "$HOME" ]]; then
  warn "家目录不同，所有路径引用会被改写为 $HOME"
fi

# ── 0. safety snapshot of the whole target tree ───────────────────────────────
STAMP="$(date +%s)"
SNAPSHOT="$HOME/.config.bak.omarchy-NTE.$STAMP"

step "0. 目标目录快照"
if [[ -d $DEST_CONFIG ]]; then
  info "  将把 $DEST_CONFIG 完整复制到 $SNAPSHOT"
  info "  （只复制小文件；体积大的浏览器/编辑器 profile 会跳过）"
  if ! $DRY_RUN; then
    mkdir -p "$SNAPSHOT"
    # --exclude protects against copying hundreds of MB of browser profiles.
    if command -v rsync >/dev/null 2>&1; then
      rsync -a \
        --exclude 'chromium/' --exclude 'Code/' --exclude 'BraveSoftware/' \
        --exclude 'google-chrome/' --exclude 'libreoffice/' --exclude 'Typora/' \
        --exclude 'Pinta/' --exclude 'node_modules/' \
        "$DEST_CONFIG/" "$SNAPSHOT/"
    else
      cp -a "$DEST_CONFIG/." "$SNAPSHOT/"
    fi
    ok "快照已保存: $SNAPSHOT"
  else
    dim "    would create $SNAPSHOT"
  fi
else
  dim "  $DEST_CONFIG 不存在，跳过快照"
fi

# ── 1. deploy regular files ───────────────────────────────────────────────────
step "1. 部署配置文件"

deployed=0 skipped=0

backup_file() {
  local target="$1"
  [[ -e $target || -L $target ]] || return 0
  local backup="$target.bak.$STAMP"
  cp -a --remove-destination "$target" "$backup"
  dim "      备份: ${backup/#$HOME/\~}"
}

deploy_file() {
  local src="$1" rel="${1#"$SRC_CONFIG"/}"
  # PATH_OVERRIDES lets a few files deploy under a different name than they are
  # stored under in git (see the wallpaper entry at the top of this script).
  local target="$DEST_CONFIG/${PATH_OVERRIDES[$rel]:-$rel}"

  $DRY_RUN || mkdir -p "$(dirname "$target")"

  # Unchanged? Then leave it alone (idempotent re-runs).
  if [[ -f $target && ! -L $target ]] && cmp -s "$src" "$target"; then
    ((skipped++)) || true
    return 0
  fi

  $DRY_RUN || backup_file "$target"
  run cp --remove-destination "$src" "$target"

  # Preserve the executable bit (Omarchy only runs executable hooks).
  if [[ -x $src ]]; then
    run chmod +x "$target"
  fi

  # NOTE: file *contents* are deployed verbatim. This repo's configs are captured
  # without hard-coded home paths: the `SUPER+D` binding that opens the DSH web UI
  # is stored as `~/.local/bin/dsh-web-open`, not `/home/<user>/...`, so it works
  # for any username. If you fork this repo and your configs do contain absolute
  # home paths, prefer replacing them with $HOME or ~ in the config itself rather
  # than patching here. Symlink *targets* still reference the capture-time home and
  # ARE rewritten — see rewrite_home() and step 2.

  ((deployed++)) || true
  if $DRY_RUN; then
    # Show the deployed name when PATH_OVERRIDES renames the file, e.g. the
    # hyphenated wallpaper landing under its original spaced filename.
    local shown="$rel" deployed_rel="${target#"$DEST_CONFIG"/}"
    if [[ $rel != "$deployed_rel" ]]; then
      shown="$rel  →  $deployed_rel"
    fi
    printf '%s    would deploy:%s %s\n' "$C_DIM" "$C_RESET" "$shown"
  fi
}

while IFS= read -r -d '' src; do
  # Symlinks are handled in step 2. `.gitkeep` placeholders only exist so git
  # keeps otherwise-empty directories; they are not deployed.
  [[ -L $src ]] && continue
  [[ $(basename "$src") == ".gitkeep" ]] && continue
  deploy_file "$src"
done < <(find "$SRC_CONFIG" -type f -print0 | sort -z)

ok "已部署 $deployed 个文件，$skipped 个已是最新"

# ── 1b. wallpaper sanity check ────────────────────────────────────────────────
# Omarchy regenerates omarchy/current/background on every theme change and points
# it at a file under omarchy/backgrounds/<theme>/. That filename contains a space,
# which is why the repo stores a hyphenated copy and PATH_OVERRIDES deploys it back
# under the spaced name. Verify the link actually resolves instead of trusting it.
step "1b. 壁纸链接检查"
bg_link="$DEST_CONFIG/omarchy/current/background"
if [[ -L $bg_link ]]; then
  bg_target="$(readlink "$bg_link")"
  if [[ -e $bg_target ]]; then
    ok "壁纸链接有效: ${bg_target/#$HOME/\~}"
  else
    warn "壁纸链接指向的文件不存在: $bg_target"
    info "  修复：omarchy theme set \"\$(omarchy theme current)\""
  fi
elif [[ -e $bg_link ]]; then
  dim "  background 不是符号链接，跳过检查"
else
  dim "  omarchy/current/background 尚不存在（首次换主题后 Omarchy 会生成）"
fi

# ── 1c. extra wallpapers from omarchy-NTE-wallpaper (optional) ────────────────
# Off unless --wallpapers was passed. The manifest is the single interface with
# the wallpaper repo; images deploy FLAT into backgrounds/<theme>/ because
# Omarchy scans that directory with `find -maxdepth 1`.
if [[ -n $WALLPAPERS ]]; then
  step "1c. 额外壁纸（可选）"

  want="$WALLPAPERS"
  if [[ $want == "__current__" ]]; then
    if ! want="$(current_theme)"; then
      warn "无法确定当前主题（找不到 theme.name）；跳过额外壁纸"
      want=""
    fi
  fi

  if [[ -n $want ]]; then
    info "  清单: $WALLPAPERS_BASE/manifests/wallpapers.tsv"
    if [[ $want == all ]]; then
      info "  主题: 清单里的所有主题"
    else
      info "  主题: $want"
    fi

    if $DRY_RUN; then
      # Deliberately no network in dry-run: we can't list files without fetching
      # the manifest, so this prints the plan only.
      dim "    would fetch the manifest, then install matching images into"
      dim "      ~/.config/omarchy/backgrounds/<theme>/（扁平，sha256 校验）"
      dim "    dry-run：不联网、不写盘"
    elif ! command -v curl >/dev/null 2>&1; then
      warn "找不到 curl，跳过额外壁纸"
    else
      wallpaper_tmp="$(mktemp -d)"
      trap 'rm -rf "$wallpaper_tmp"' EXIT

      wall_installed=0 wall_skipped=0 wall_failed=0 wall_matched=0

      if ! curl -fsSL --max-time 30 "$WALLPAPERS_BASE/manifests/wallpapers.tsv" \
           -o "$wallpaper_tmp/wallpapers.tsv"; then
        warn "清单下载失败，跳过额外壁纸: $WALLPAPERS_BASE/manifests/wallpapers.tsv"
        wall_failed=$((wall_failed + 1))
      else
        while IFS=$'\t' read -r w_theme w_id w_file w_preview w_sha w_bytes w_width w_height w_title w_bundled w_credit w_source; do
          [[ $w_theme == "theme" ]] && continue
          [[ $want == all || $w_theme == "$want" ]] || continue
          wall_matched=$((wall_matched + 1))

          dest_dir="$HOME/.config/omarchy/backgrounds/$w_theme"
          dest="$dest_dir/$(basename "$w_file")"

          # Already there with the same bytes? Nothing to do (idempotent reruns).
          if [[ -f $dest && "$(sha256sum "$dest" | cut -d' ' -f1)" == "$w_sha" ]]; then
            wall_skipped=$((wall_skipped + 1))
            continue
          fi

          # bundled=1: the config repo already ships this image, possibly under a
          # spaced filename. sha256 is the only reliable way to recognise it.
          if [[ $w_bundled == 1 && -d $dest_dir ]] \
             && find "$dest_dir" -maxdepth 1 -type f -exec sha256sum {} + 2>/dev/null \
                | awk -v want="$w_sha" '$1 == want { found = 1 } END { exit !found }'; then
            wall_skipped=$((wall_skipped + 1))
            continue
          fi

          tmpfile="$wallpaper_tmp/$(basename "$w_file")"
          if ! curl -fsSL --max-time 120 "$WALLPAPERS_BASE/$w_file" -o "$tmpfile"; then
            warn "下载失败: $w_file"
            wall_failed=$((wall_failed + 1))
            continue
          fi
          if ! printf '%s  %s\n' "$w_sha" "$tmpfile" | sha256sum -c - >/dev/null 2>&1; then
            warn "校验失败: $w_file"
            wall_failed=$((wall_failed + 1))
            continue
          fi

          backup_file "$dest"
          if ! install -Dm0644 "$tmpfile" "$dest"; then
            warn "写入失败: $dest"
            wall_failed=$((wall_failed + 1))
            continue
          fi
          ok "已安装 ${w_title:-$w_id} → backgrounds/$w_theme/$(basename "$w_file")"
          wall_installed=$((wall_installed + 1))
        done <"$wallpaper_tmp/wallpapers.tsv"

        if (( wall_matched == 0 )); then
          warn "清单里没有主题 '$want'（可查 $WALLPAPERS_BASE/manifests/wallpapers.tsv）"
          wall_failed=$((wall_failed + 1))
          wallpaper_usage_error=true
        fi
      fi

      ok "额外壁纸：安装 $wall_installed，跳过 $wall_skipped，失败 $wall_failed"
      if (( wall_failed > 0 )); then
        warn "有壁纸未能安装；配置部署已完成，可稍后重跑 ./install.sh --wallpapers"
      elif (( wall_installed + wall_skipped > 0 )); then
        case "$(omarchy version 2>/dev/null | head -n1)" in
          4.*) info "  切换壁纸：Super+Ctrl+W（Omarchy 4.x）" ;;
          *)   info "  切换壁纸：Super+Ctrl+Space（Omarchy 3.8.2）" ;;
        esac
      fi
    fi
  fi
fi

# ── 2. rebuild the theme-following symlinks ───────────────────────────────────
step "2. 重建主题跟随符号链接"

# These point into ~/.config/omarchy/current/theme/, which Omarchy regenerates on
# every theme change. Recreating them (rather than copying file contents) is what
# keeps mako/btop/nvim in sync with the active theme.
link_count=0
while IFS= read -r -d '' src; do
  rel="${src#"$SRC_CONFIG"/}"
  target="$DEST_CONFIG/$rel"
  new_dest="$(rewrite_home "$(readlink "$src")")"

  $DRY_RUN || mkdir -p "$(dirname "$target")"

  if [[ -L $target && "$(readlink "$target")" == "$new_dest" ]]; then
    dim "      已是正确链接: $rel"
    continue
  fi

  $DRY_RUN || backup_file "$target"
  if $DRY_RUN; then
    printf '%s    would link:%s %s -> %s\n' "$C_DIM" "$C_RESET" "$rel" "$new_dest"
  else
    ln -snf "$new_dest" "$target"
  fi

  # Warn if the link target does not exist yet. It is generated by Omarchy on
  # theme change, so this is expected on a brand-new machine.
  if [[ ! -e $new_dest ]]; then
    warn "链接目标尚不存在（换主题后 Omarchy 会生成）: $new_dest"
  fi
  ((link_count++)) || true
done < <(find "$SRC_CONFIG" -type l -print0 | sort -z)

ok "已重建 $link_count 个符号链接"

# ── 2b. recreate directories tracked only by a .gitkeep placeholder ───────────
# e.g. config/omarchy/themes/ — the repo keeps them alive with .gitkeep, which we
# deliberately do not deploy, so the directory has to be created explicitly.
while IFS= read -r -d '' dir; do
  rel="${dir#"$SRC_CONFIG"/}"
  target="$DEST_CONFIG/$rel"
  [[ -d $target ]] && continue
  run mkdir -p "$target"
  if $DRY_RUN; then
    printf '%s    would create dir:%s %s\n' "$C_DIM" "$C_RESET" "$rel"
  else
    ok "已创建目录 $rel"
  fi
done < <(find "$SRC_CONFIG" -name '.gitkeep' -printf '%h\0' | sort -zu)

# ── 2c. deploy the DSH profile and its local plugins (optional) ───────────────
# dsh/ mirrors ~/.dsh exactly, so the profile's relative "link:../../plugins/..."
# specs resolve both inside the repo and after deployment. node_modules is not
# tracked; the deployed profile needs `pnpm install` before it will run.
SRC_DSH="$REPO_DIR/dsh"
if [[ -d $SRC_DSH ]]; then
  step "2c. DSH 配置与本地插件"

  dest_profile="$HOME/.dsh/profiles/web"
  dest_plugins="$HOME/.dsh/plugins"
  dsh_deployed=0 dsh_skipped=0

  while IFS= read -r -d '' src; do
    rel="${src#"$SRC_DSH"/}"
    case "$rel" in
      profiles/web/*) target="$dest_profile/${rel#profiles/web/}" ;;
      plugins/*)      target="$dest_plugins/${rel#plugins/}" ;;
      *)              continue ;;
    esac

    $DRY_RUN || mkdir -p "$(dirname "$target")"
    if [[ -f $target ]] && cmp -s "$src" "$target"; then
      ((dsh_skipped++)) || true
      continue
    fi

    $DRY_RUN || backup_file "$target"
    run cp --remove-destination "$src" "$target"
    ((dsh_deployed++)) || true
    if $DRY_RUN; then
      printf '%s    would deploy:%s dsh/%s\n' "$C_DIM" "$C_RESET" "$rel"
    fi
  done < <(find "$SRC_DSH" -type f -print0 | sort -z)

  ok "DSH：已部署 $dsh_deployed 个文件，$dsh_skipped 个已是最新"
  if ! $DRY_RUN && (( dsh_deployed > 0 )); then
    info "  依赖还没安装。要让配置生效，执行："
    info "    cd $dest_profile && pnpm install"
  fi
else
  dim "  未找到 dsh/，跳过 DSH 配置"
fi

# ── 2d. dsh-wakatime：把 DSH 的文件操作同步到 WakaTime（可选） ────────────────
# bin/ 里的脚本安装到 ~/.local/bin；systemd unit 由第 1 步随 config/ 一起部署，
# 定时器在第 3 步启用。API key 不在仓库里，运行时读 ~/.wakatime.cfg。
SRC_BIN="$REPO_DIR/bin"
if [[ -d $SRC_BIN ]]; then
  step "2d. dsh-wakatime（DSH 活动 → WakaTime）"
  run mkdir -p "$HOME/.local/bin"
  bin_deployed=0 bin_skipped=0
  while IFS= read -r -d '' src; do
    name="$(basename "$src")"
    target="$HOME/.local/bin/$name"
    if [[ -f $target ]] && cmp -s "$src" "$target"; then
      ((bin_skipped++)) || true
      continue
    fi
    if $DRY_RUN; then
      printf '%s    would deploy:%s ~/.local/bin/%s\n' "$C_DIM" "$C_RESET" "$name"
    else
      backup_file "$target"
      cp --remove-destination "$src" "$target"
      chmod +x "$target"
    fi
    ((bin_deployed++)) || true
  done < <(find "$SRC_BIN" -type f -print0 | sort -z)
  ok "脚本：已部署 $bin_deployed 个，$bin_skipped 个已是最新"
  dsh_wakatime_ok=true
  if ! $DRY_RUN && [[ -x $HOME/.local/bin/dsh-wakatime ]]; then
    if ! "$HOME/.local/bin/dsh-wakatime" doctor; then
      dsh_wakatime_ok=false
      warn "doctor 未全部通过，本次不启用 timer（补齐后再 enable）"
    fi
  fi
else
  dim "  未找到 bin/，跳过 dsh-wakatime"
fi

# ── 3. systemd user units ─────────────────────────────────────────────────────
step "3. systemd 用户单元"

if command -v systemctl >/dev/null 2>&1; then
  # elephant.service is enabled by Omarchy's own refresh; re-enable defensively
  # so the Eleemosynary menus keep working.
  for unit in elephant.service; do
    if [[ -f $DEST_CONFIG/systemd/user/$unit ]]; then
      run systemctl --user daemon-reload
      run systemctl --user enable "$unit"
      ok "已启用 $unit"
    fi
  done
  if [[ -f $DEST_CONFIG/systemd/user/dsh-wakatime.timer ]] && ${dsh_wakatime_ok:-true}; then
    run systemctl --user daemon-reload
    run systemctl --user enable --now dsh-wakatime.timer
    ok "已启用 dsh-wakatime.timer（每 2 分钟同步 DSH 活动）"
  elif [[ -f $DEST_CONFIG/systemd/user/dsh-wakatime.timer ]]; then
    warn "已跳过 dsh-wakatime.timer 的启用（doctor 未通过）"
  fi
  dim "  dsh-web.service 不会被自动启用（它属于 DSH 界面，见 README）"
else
  warn "找不到 systemctl，跳过服务启用"
fi

# ── 4. fcitx5 ─────────────────────────────────────────────────────────────────
step "4. 输入法（fcitx5）"

if command -v fcitx5 >/dev/null 2>&1; then
  if systemctl --user is-active app-org.fcitx.Fcitx5@autostart.service >/dev/null 2>&1; then
    info "  重启 fcitx5 以载入新配置"
    run systemctl --user restart app-org.fcitx.Fcitx5@autostart.service
    ok "fcitx5 已重启"
  else
    dim "  fcitx5 未在运行，登录后会自动启动"
  fi
  dim "  主题 catppuccin-mocha-blue 由 AUR 包提供："
  dim "    omarchy pkg aur add catppuccin-fcitx5-git"
else
  warn "未安装 fcitx5，跳过"
fi

# ── done ──────────────────────────────────────────────────────────────────────
step "完成"
if $DRY_RUN; then
  info "  这是 DRY-RUN：没有任何文件被修改。"
  info "  去掉 --dry-run 即可真正部署。"
else
  info "  配置快照: $SNAPSHOT"
  info "  单独文件的备份: *${C_DIM}.bak.$STAMP${C_RESET}"
  echo
  info "  建议下一步："
  info "    omarchy restart waybar      # 让 waybar 重新读取配置"
  info "    hyprctl reload              # 让 Hyprland 重新读取配置"
  info "    hyprctl configerrors        # 确认没有配置错误"
fi

if $wallpaper_usage_error; then
  printf '%sERROR:%s 请求的壁纸主题不存在（配置本身已部署完成）。\n' "$C_RED" "$C_RESET" >&2
  exit 1
fi
