# omarchy-NTE

我的 [Omarchy](https://omarchy.org/) 桌面个性化配置 —— 主题、输入法、窗口管理器、终端、
以及把它们带到一台新机器上的方法。

> **这个仓库包含什么**：只包含**我真正改过的东西**。
> 每个文件都与 Omarchy 官方默认值逐字节比对过，一致的一律不收。

---

## 内容一览

| 内容 | 位置 |
|---|---|
| Hyprland / Waybar / Walker / Mako / 终端配置 | `config/hypr/`、`config/waybar/` 等 |
| **输入法（fcitx5）** | `config/fcitx5/` |
| **自动跟随主题的输入法钩子** | `config/omarchy/hooks/theme-set.d/fcitx5-follow` |
| Omarchy branding、壁纸 | `config/omarchy/branding/`、`config/omarchy/backgrounds/` |
| Neovim | `config/nvim/` |
| 复现所需的包清单 | `packages/` |

**不装什么**：任何凭据、浏览器/编辑器 profile、Omarchy 官方源码、生成状态、运行时缓存。
规则见 [.gitignore](.gitignore)。

---

## 当前桌面状态

- **Omarchy** 3.8.2 · Arch Linux · Hyprland (Wayland) · btrfs
- 主题：**Catppuccin**（Mocha，accent `#89b4fa`）
- 输入法：**fcitx5 5.1.19**
  - 面板主题 `catppuccin-mocha-blue`，字号 `Sans 13`
  - 主题由 AUR 包 [`catppuccin-fcitx5-git`](https://aur.archlinux.org/packages/catppuccin-fcitx5-git) 提供
    （56 个变体，含圆角），因此可随 `omarchy update` 自动更新
  - 换 Omarchy 主题时，`fcitx5-follow` 钩子会自动同步输入法配色

---

## ⚠️ 设计上最重要的一点：为什么用复制而不是 stow

Omarchy 官方手册推荐用 [stow](https://omarchy.org/manual/dotfiles/) 管理 dotfiles
（即把 `~/.config/X` 符号链接到仓库）。**本仓库故意不这么做**，因为在本机实测会坏：

`omarchy-refresh-config` 内部是 `cp -f`，**没有** `--remove-destination`，
因此会**跟随符号链接、直接改写链接的目标文件**：

```
cfg/t.conf -> repo/real.conf   （符号链接）
cp -f new.conf cfg/t.conf
→ 符号链接保留，repo/real.conf 的内容被覆盖   ← 你的仓库被 Omarchy 静默改写
```

所以：

- ❌ **stow 式符号链接** → `omarchy refresh hyprland` 会污染你的仓库
- ✅ **复制式 `install.sh`** → 仓库是「模板」，完全免疫 refresh / reinstall

代价：改完 `~/.config` 后要重新同步回仓库。收益：配置永远不会被 Omarchy 悄悄改掉。

完整证据链（含源码行号与实测输出）见


---

## 在新机器上恢复

> **前提**：已经装好 Omarchy（<https://omarchy.org/>）。
> **注意**：`install.sh` **不需要 sudo**，它只写 `$HOME` 里的东西。

### 1. 克隆

```bash
git clone https://github.com/CAI991108/omarchy-NTE.git ~/Projects/omarchy-NTE
cd ~/Projects/omarchy-NTE
```

### 2. 安装软件包（**需要 sudo，请先人工过一遍清单**）

```bash
# 官方仓库的显式包（192 个）—— 清单来自 packages/pacman-explicit.txt
less packages/pacman-explicit.txt          # 先看一眼，确认没有不该装的
sudo pacman -S --needed - < packages/pacman-explicit.txt

# AUR / 外来包（7 个）
cat packages/aur-explicit.txt
omarchy pkg aur add catppuccin-fcitx5-git
```

`packages/environment.txt` 记录了我当时的系统快照（主机名、内核、文件系统、版本），
可用于核对差异。

### 3. 部署配置

```bash
./install.sh --dry-run     # 先看会改什么，不写入任何文件
./install.sh               # 真正部署
```

`install.sh` 的行为：

- **先备份**：整个 `~/.config` 快照到 `~/.config.bak.omarchy-NTE.<时间戳>`；
  每个被覆盖的文件另存为 `<文件>.bak.<时间戳>`。**不删除任何东西。**
- **幂等**：内容相同的文件直接跳过，可以反复运行。
- **重建符号链接**：`mako/config`、`btop/themes/current.theme`、
  `nvim/lua/plugins/theme.lua` 这三个指向 `omarchy/current/theme/` 的链接会被重新建立，
  并把其中的家目录路径改写为当前用户的 `$HOME`
  （它们是主题自动跟随的关键）。
- **保留可执行位**：钩子必须是可执行的，否则 Omarchy 不会运行它。
- **不碰 sudo**：只写 `$HOME` 里的文件。

### 4. 让改动生效

```bash
omarchy restart waybar
hyprctl reload
hyprctl configerrors       # 确认没有配置错误
systemctl --user restart app-org.fcitx.Fcitx5@autostart.service
```

### 5. 壁纸

本仓库只带了**当前那一张**壁纸，放在
`config/omarchy/backgrounds/catppuccin/` —— 正是 Omarchy 会自动扫描的路径。
按 `Super + Ctrl + Space` 选它即可。其余 9 张未纳入（见下方「已知取舍」）。

---

## 目录结构

```
omarchy-NTE/
├── install.sh                       # 复制式部署：先备份、幂等、支持 --dry-run
├── config/                          # 镜像 ~/.config（只含用户改动）
│   ├── hypr/ waybar/ mako/ alacritty/ ghostty/ kitty/ btop/
│   ├── fcitx5/                      # 输入法（Theme / Font 在这里）
│   ├── omarchy/
│   │   ├── hooks/theme-set.d/fcitx5-follow    ⭐ 唯一的自定义钩子
│   │   ├── branding/                # fastfetch + 锁屏 ASCII 图案
│   │   ├── backgrounds/catppuccin/  # 当前壁纸
│   │   └── themes/                  # 自定义主题（暂空，留给以后）
│   ├── nvim/ systemd/ fontconfig/ git/ ...
│   └── *.conf  mimeapps.list  user-dirs.dirs 等散文件
├── packages/                        # 包清单与环境快照
```

---

## 已知取舍

| 取舍 | 说明 |
|---|---|
| **壁纸只留 1 张** | 其余 9 张（约 13 MB）未纳入，避免 git 历史永久变重。需要时从原处自行复制到 `~/.config/omarchy/backgrounds/<主题名>/`。 |
| **DSH 插件配置未纳入** | `~/.dsh/profiles/web/` 是本 AI 界面的配置，严格说不属于桌面配置。其中 `systemd/user/dsh-web.service` **有**纳入（它是用户自己写的单元）。 |
| **`git/config` 是精简版** | 它去掉了 Omarchy 默认的一些实用设置（`rerere`、`autoSetupRemote`、`diff.algorithm` 等），另外仓库版本**已移除 `[user]` 身份**。 |
| **`config/omarchy/current/` 未纳入** | 生成状态，每次换主题被整个重建。 |
| **5 个 `.sample` 钩子未纳入** | 经比对与 Omarchy 默认逐字节相同，属官方默认值。 |

---

## 安全

本仓库在设计上**排除所有凭据**：

- `.gitignore` 顶部有一组凭据红线（`gh/`、`*.key`、`*.pem`、`Trust Tokens*`、`.env*` 等）
- `~/.config/gh/hosts.yml`（含 GitHub CLI 的 oauth token）经 git 规则实测**不会入库**
- 仓库内的 `git/config` **已移除**真实姓名与 CUHK 邮箱

### ⚠️ 但提交元数据仍然会带上邮箱

`git commit` 会把 `user.name` / `user.email` 写进**每一个 commit**，
这不在 `.gitignore` 能管的范围内。本机的全局身份里带着真实邮箱，
**公开仓库里它会永久可搜、难以撤回**。

**本仓库已经处理好了** —— 仓库级身份已设为 GitHub noreply，没有改动你的全局设置：

```bash
$ git config user.name     # → CAI991108
$ git config user.email    # → 89437236+CAI991108@users.noreply.github.com
$ git config --global user.email   # → 仍是你的全局邮箱，未被改动
```

数字 ID 形式的 noreply 邮箱是 GitHub 官方推荐做法，能正常关联到你的账号，
同时不公开真实邮箱。

如果你在别处克隆本仓库并提交，请自行设置；自查命令：

```bash
git log --format='%an <%ae>' | sort -u      # 列出所有出现过的作者身份
```

### 自查命令

```bash
git ls-files | grep -iE 'token|secret|credential|hosts\.yml|\.pem|\.key'
find . -iname '*token*' -o -iname '*.key' -o -iname '*.pem' -o -iname '.env*'
grep -rIn -iE '你的邮箱前缀|你的学校域名' . --exclude-dir=.git
```

任何凭据都不应出现在版本历史里 —— 一旦提交过，**改密码比删文件更重要**（历史可被恢复）。

---

## 许可

我的配置文件部分可随意取用。`config/nvim/` 源自 LazyVim / `omarchy-nvim` 包，
其 `LICENSE` 随文件保留。
