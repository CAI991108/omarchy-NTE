# DSH 配置（AI 界面）

`~/.dsh` 是 DeepSeek Harness（DSH）的配置根。这里保存的是本机正在用的
**web profile** 和两个**本地插件**，用于在新机器上还原同一套界面。

## 目录布局

布局刻意与 `~/.dsh` **一一对应**，这样 `package.json` 里的相对
`link:../../plugins/...` 在「仓库内」和「部署后」两种位置都指向同一处：

```
dsh/
├── profiles/web/            # → 部署到 ~/.dsh/profiles/web
│   ├── cordis.yml           # profile 根（空数组，实际由 patch 层组成）
│   ├── cordis.patch.yml     # 你的 patch 层：UI、权限预设、默认模型等
│   ├── package.json         # 插件清单；本地插件用相对 link:
│   ├── pnpm-workspace.yaml  # patchedDependencies + 版本豁免
│   ├── pnpm-lock.yaml       # 锁文件（保证依赖版本可复现）
│   └── patches/             # 对第三方包的补丁
└── plugins/                 # → 部署到 ~/.dsh/plugins
    ├── dsh-brand-cover/
    └── dsh-effort-slider/
```

## 与真实的 `~/.dsh` 的差别

| 内容 | 处理 |
|---|---|
| `node_modules/` | **不跟踪**（体积大、可由锁文件重建） |
| `.plugin-manager/` | **不跟踪**（运行时状态） |
| `link:` 依赖 | 已从绝对路径 `/home/<用户>/.dsh/...` 改为 **相对路径** `../../plugins/...` |

## 部署

`install.sh` 会自动把 `profiles/web/` 与 `plugins/` 复制到对应位置（先备份）。
复制完成后依赖尚未安装，需要手动跑一次：

```bash
cd ~/.dsh/profiles/web && pnpm install
```

> 这一步需要网络（要拉 npm 上的第三方插件），所以没有写进 `install.sh`。

## 静默启动

`config/systemd/user/dsh-web.service` 把 `dsh web --no-open` 交给 systemd 用户管理器，
`bin/dsh-web-open` 负责「没起就起、起了就开窗口」，`SUPER + D` 绑的是后者。
终端窗口在这一路上不存在。

服务用 mise 的 shim（`~/.local/share/mise/shims/dsh`）而不是钉死版本号，
所以升级 DSH 是 `mise use -g npm:@deepseek-ai/dsh@<版本>` 的事，不用改单元文件。
URL 带一次性 browser-trust token，写在 `~/.local/state/dsh-web/server.log` 里给启动器读。

## 换机器时要留意

- **模型 provider**：`cordis.patch.yml` 里默认 `deepseek-account`（登录态）。
  若改用 API key，把它换成 `deepseek-official`，否则新会话取不到模型。
- `install.sh` 会部署单元文件，但**不会自动 enable**；要不要开机自启由你决定：
  `systemctl --user enable dsh-web.service`。
- 本目录记录的是**界面配置**，与 `config/`（桌面配置）互不影响。
