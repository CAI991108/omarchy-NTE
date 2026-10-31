# Omarchy 4.0：配置面、抓取方法与坑

这份文档记录 `main` 为什么长成现在这样。它面向两件事：**(a)** 下次在这台机器上改配置时，判断一个文件该不该进仓库；**(b)** 下一代 Omarchy 断代时，照着重做一遍抓取。

> **渠道前缀**：本机跑的是 `omarchy-dev` 的 `quattro` 开发分支（写作时 `4.0.0.r7442.gbda3aaf-1`），不是发布版。截至 2026-10-31，最新发布是 `v4.0.6`（2026-10-19）。两者已经 diverge，凡是只在 `quattro` 上的行为，下文都会显式标注。**别把「开发分支上成立」当成「发布版也成立」。**

配套决定见 [`docs/adr/0002-omarchy-4-cut.md`](adr/0002-omarchy-4-cut.md)。

## 1. 4.0 换了什么

| 3.8.2 | 4.0 |
|---|---|
| `~/.config/hypr/*.conf` | `~/.config/hypr/*.lua`（`hl.config` / `o.bind` / `o.window`） |
| waybar | Quickshell 的 bar：`~/.config/omarchy/shell.json` 的 `bar.layout` |
| mako | Quickshell 的通知服务（`omarchy.notifications`），`shell.json` 里配 |
| walker | Quickshell menu（`SUPER + SPACE` = `{ menu = "root" }`）+ `extensions/omarchy-menu.jsonc` |
| hypridle / hyprlock | **应用已删**，空闲行为在 `shell.json` 的 `idle.{screensaver,lock}` |
| `~/.config/omarchy/current/` | `~/.local/state/omarchy/current/`（主题、背景指针都在这里） |
| fcitx5 主题靠自定义钩子 | `quattro` 上由 `omarchy-theme-set-fcitx5` 内置生成 `~/.local/share/fcitx5/themes/omarchy`；**`v4.0.6` 正式版里这个脚本仍是 404**，发布版用户仍需自己的做法 |
| 官方 systemd 单元在 `~/.config/systemd/user` | 装在 `/usr/lib/systemd/user`；`~/.config/...` 只放用户自己的单元和 `.wants` 链接 |

`hyprsunset.conf` 和 `xdph.conf` 仍然是 `.conf`，但它们由 hyprsunset / portal 读，不归 Hyprland。Hyprland 0.57 的 `hyprland.log` 里能看到实际入口：

```
[Config::initConfigManager] [cfg] Regular config at /home/<user>/.config/hypr/hyprland.lua
```

## 2. 抓取方法（下次断代照做）

判据（也写在 `AGENTS.md`）：**与 `$OMARCHY_PATH/config/<同路径>` 有差异，或没有模板但我维护**。第三步的核对清单比判据本身更重要——它能抓出「机器上改过、但和模板恰好一样」的东西。

**节奏**：下一次全量抓取排在 **2026-11-14**，和 `packages/` 重抓在同一次里做完（[ADR-0004](adr/0004-defer-capture-to-2026-11-14.md)、票 #16）。在那之前机器还在改，**不零散抓取、也不部署**——现在部署会把机器上更新的值（fcitx5 默认输入、bar 时钟格式、终端字体）覆盖回去。

```bash
# 1. 候选：机器上有、模板里没有，或内容不同
diff -rq "$HOME/.config" "${OMARCHY_PATH:-/usr/share/omarchy}/config" | head -50

# 2. 筛：删掉应用自己管理的运行时状态
#    （fcitx5 的 cached_layouts、user-dirs.*、mimeapps 里的自动条目、*.sock、
#     node_modules、浏览器 profile）

# 3. 核对：拿上一代的树逐项过，防止漏掉「模板里也有、但我依赖它」的东西
git ls-tree -r --name-only omarchy-3.8.2 -- config | \
  while read -r f; do printf '%s: ' "$f"; \
    [[ -e $HOME/${f#config/} ]] && echo present || echo MISSING; done | grep MISSING
```

第 3 步这一步在 4.0 抓取时抓出了两样光看 diff 会漏的东西：终端字体的不一致（机器上是 4.0 默认的 `JetBrainsMono`，仓库里是 3.8.2 时的 `CaskaydiaMono`，**原因未查清**——本机没留下 `omarchy-upgrade-to-quattro` 的迁移痕迹），以及 `fontconfig/fonts.conf`（模板没有、机器上也没有，但仓库里它是刻意的字体替换）。

**不要抓**：`git/config`（live 里有 `[user]` / `[credential]`，公开仓库会泄露身份；仓库版是刻意剥掉这两段的）、`monitors.lua`（分辨率/缩放是机器属性）、模板自带的 `hyprland.lua`/`input.lua`/`looknfeel.lua`/`autostart.lua`、`extensions/omarchy-menu.jsonc`（与默认一致时）。

## 3. `.conf` → `.lua` 对照

| 旧 | 新 |
|---|---|
| `source = …` | `dofile(...)` / `require("hypr.x")` |
| `bindd = SUPER, X, Desc, exec, cmd` | `o.bind("SUPER + X", "Desc", "cmd")` |
| `unbind = SUPER, X` | `hl.unbind("SUPER + X")` |
| `monitor = …`, `env = …` | `hl.monitor{...}` / `hl.config({monitor = ...})` / `hl.env` |
| `input { … }` | `hl.config({ input = { ... } })` |
| `windowrule = …` | `o.window("class", { ... })` |
| `exec-once = …` | `o.launch_on_start("...")` |
| 声明式绑定 | `{ launch = "cmd" }`、`{ webapp = "https://…" }`、`{ tui = "…" }`、`{ menu = "root" }` |

`envs.conf` **没有对应文件**：个人环境变量写进 `hyprland.lua` 的 `hl.env`。

## 4. 钩子

机制没变：`~/.config/omarchy/hooks/<event>/` 放可执行文件，`<event>.d/*` 逐个 `bash` 执行。事件有六个：`battery-low`、`font-set`、`post-boot`、`post-update`、`pre-refresh-pacman`、`theme-set`。

装钩子**用官方命令**，不要手抄（它会 `chmod 755` 并放对目录）：

```bash
omarchy hook install theme-set path/to/hook
```

`theme-set` 的 fcitx5 上色在 `quattro` 上已经内置（发布版 `v4.0.6` 还没有），所以本仓库不再自带任何钩子；用正式版的机器需要自己上色。

## 5. 主题与状态路径

- 覆盖层仍然是 `~/.config/omarchy/themes/<slug>/`：`omarchy theme set` 先把官方主题复制到 `next-theme`，再把用户目录覆盖上去。`colors.toml`、`shell.toml`、`backgrounds/`、`fcitx5-theme.conf` 这些按名字被消费。
- 当前主题的产物在 **`~/.local/state/omarchy/current/theme/`**。仓库里唯一跟随主题的软链（btop）指向这里。
- 壁纸仍从 `~/.config/omarchy/backgrounds/<slug>/` 找（用户目录）；主题自带的在 `~/.local/state/omarchy/current/theme/backgrounds/`，切换器两个目录都扫。
- 当前背景指针在 **`~/.local/state/omarchy/current/background`**（3.8.2 在 `~/.config/omarchy/current/background`）。`install.sh` 的「壁纸链接检查」按这两个路径依次找；只认 3.8 那条会在 4.0 上永远显示「尚不存在」。

## 6. 三个会咬人的地方

1. **`omarchy-refresh-config` 仍然是 `cp -f`，会穿透软链**（4.0 的 `/usr/bin/omarchy-refresh-config:31-33` 逐行确认过：没有 `--remove-destination`、没有 `-P`）。所以本仓库部署的是**副本**而不是软链——否则一次 refresh 就把仓库里的文件改掉。
2. **`omarchy refresh shell` 会重置 bar 布局**：它先 `omarchy-refresh-config omarchy/shell.json`（这一步**会**留下 `shell.json.bak.<epoch>`），再 `omarchy-bar defaults` 把 `shell.json` 重写掉。所以定制**可以**从备份里捞回来，但别把「有备份」理解成「什么都没丢」。
3. **`omarchy refresh hyprland` 对 `~/.local/state/omarchy/toggles/flags.lua` 不备份**（其余七个文件有 `.bak.<epoch>`）。

## 7. DSH 静默启动

`SUPER + D` → `~/.local/bin/dsh-web-open` → 没有服务就 `systemctl --user start dsh-web` → 开 Chromium 应用窗口。

- 单元：[`config/systemd/user/dsh-web.service`](../config/systemd/user/dsh-web.service)，`--no-open`，日志追加到 `~/.local/state/dsh-web/server.log`
- 启动器：[`bin/dsh-web-open`](../bin/dsh-web-open)；窗口已存在则聚焦（优先应用窗口，其次浏览器标签页）
- 开机自启是**可选**的：`systemctl --user enable dsh-web.service`
- 浏览器信任是**按次 token**：每次启动 `dsh web` 都会打印新的 `?token=…`，启动器从日志里取最新一条

## 8. 部署后怎么验

```bash
./install.sh --dry-run              # 期望：只剩刻意的差异（终端字体、git identity 等）
hyprctl reload && hyprctl configerrors
omarchy restart terminal
omarchy restart shell
```
