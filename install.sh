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
#   ./install.sh                 # deploy
#   ./install.sh --dry-run       # show what would change, touch nothing

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

DRY_RUN=false
(( $# > 0 )) && [[ $1 == "--dry-run" ]] && DRY_RUN=true

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
  local src="$1" rel="${1#"$SRC_CONFIG"/}" target="$DEST_CONFIG/${1#"$SRC_CONFIG"/}"

  mkdir -p "$(dirname "$target")"

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

  # NOTE: file *contents* are deployed verbatim. This repo's configs were
  # captured without hard-coded home paths (the one `SUPER+D` binding that had
  # `/home/<user>/...` was deliberately removed), so there is nothing to rewrite.
  # If you fork this repo and your configs do contain absolute home paths, prefer
  # replacing them with $HOME or ~ in the config itself rather than patching here.
  # Symlink *targets* still reference the capture-time home and ARE rewritten —
  # see rewrite_home() and step 2.

  ((deployed++)) || true
  if $DRY_RUN; then
    printf '%s    would deploy:%s %s\n' "$C_DIM" "$C_RESET" "$rel"
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

  mkdir -p "$(dirname "$target")"

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
