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

## 换机器时要留意

- DSH 自身的版本由 `config/systemd/user/dsh-web.service` 里的 `dsh@<版本>`
  钉住，与本目录的插件版本配套；升级 DSH 后建议同时重新捕获这份配置。
- 本目录记录的是**界面配置**，与 `config/`（桌面配置）互不影响。
