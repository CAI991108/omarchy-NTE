# GLOSSARY

这个仓库的词汇表。只收那些会漂移、且在这份代码库里有确切含义的词。
排版约定：**中文为主，术语保留英文原词**——因为代码里的标识符（`TREES`、
`deploy_copy`、`omarchy-refresh-config`）是英文，翻译会把两者拆散。

## 部署相关

**tree（树）** — 仓库里的一棵目录，一一对应 `$HOME` 下的某个目录：
`config/` → `~/.config`、`dsh/` → `~/.dsh`、`bin/` → `~/.local/bin`。加一棵树就是
`install.sh` 里 `TREES` 数组的一行。不叫「模块」「组件」。

**handler** — `install.sh` 里处理单个文件的函数（`deploy_config_file`、
`deploy_plain_file`、`deploy_executable_file`）。循环负责发现/备份/幂等/dry-run，
handler 只负责这个文件特有的动作（改名、加可执行位）。

**deploy（部署）** — 把仓库内容**复制**到 `$HOME`。是 copy，不是软链：Omarchy 的
`omarchy-refresh-config` 用 `cp -f`，会**穿透**软链写回仓库。

**dry-run** — 只打印计划、不写盘。`--dry-run` 时也**不联网**。

**capture（抓取）** — 把机器上的配置收进仓库。判据见下节 `config surface`。

## 版本与配置面

**cut（断代）** — 一次大版本跨越（这里是 3.8.2 → 4.0），配置面被替换、旧树只剩历史
价值。断代的结果是 `main` 上一套新树 + 旧树打 tag，不是双轨。

**config surface（配置面）** — Omarchy 实际读取的那组文件。4.0 的配置面是
`~/.config/hypr/*.lua`、`~/.config/omarchy/{shell.json,defaults/,themes/,hooks/,extensions/}`、
`~/.config/systemd/user/`。判据：**与 `$OMARCHY_PATH/config/<同路径>` 有差异，或没有模板
但我维护**——前者是「我改的」，后者是「我持有的产物」。

**shipped default（随包默认 / 模板）** — `$OMARCHY_PATH/config/` 下由 Omarchy 提供的那份。
与它逐字节相同的东西**不进仓库**：抄得越多，腐烂得越快。

**drift（漂移）** — 仓库与机器不再一致。既包括「机器上改了没抓」，也包括「升级把机器重置
而仓库还是旧偏好」（终端字体就是这么丢的）。

**overlay（覆盖层）** — `~/.config/omarchy/themes/<slug>/` 叠在官方主题上的那层，
`omarchy theme set` 时按文件名消费（`colors.toml`、`shell.toml`、`backgrounds/`…）。

**snapshot（快照）** — 库存整文件，不做字段级合并。代价是模板注释不再跟随上游；
换来的是 `shell.json` 这种被 `omarchy bar` 整份重写的配置能被还原。

**runtime state（运行时状态）** — 应用自己写、用户没碰过的文件（`user-dirs.*`、
fcitx5 的 `cached_layouts`、`mimeapps.list` 里的自动条目）。抓取时排除。
