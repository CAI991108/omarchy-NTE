-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- DeepSeek Harness: starts the headless dsh-web user service if needed, then
-- focuses the running UI or opens it as a web app. No terminal window.
-- (SUPER + SHIFT + D stays Docker.)
o.bind("SUPER + D", "DeepSeek Harness", os.getenv("HOME") .. "/.local/bin/dsh-web-open")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- 按住说话：走 voxtype-ctl.sh（ADR 0004：按需启停，接电走独显+turbo、电池走核显+small）。
-- 冷启动约 1 秒，所以第一次按会比热启慢；顶栏组件负责提前预热。
-- 用 bind_hold 而不是 bind，松开按键才会停；release 半段是 transparent +
-- non_consuming 的，不会把 SUPER+H 从应用手里抢走。
local dictate = os.getenv("HOME") .. "/文档/deepseek-harness/default-workspace/topics/voxtype/voxtype-ctl.sh"
o.bind_hold(
  "SUPER + H",
  "Start dictation (push-to-talk)",
  dictate .. " record start",
  "Stop dictation (push-to-talk)",
  dictate .. " record stop"
)
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
-- Display：原生 omarchy.monitor 已从顶栏移除；SUPER+CTRL+D 改开 hyprmoncfg 的面板。
o.rebind("SUPER + CTRL + D", "Display (hyprmoncfg)", { panel = "crmne.hyprmoncfg" })

-- B 站歌单：用 cliamp 打开合并后的「B站 - 全部」并自动播放。
-- 普通 cliamp 仍是 Omarchy 自带的 SUPER + SHIFT + ALT + M。
-- 播放列表由 topics/cliamp/sync-bilibili-playlists.py 生成，标题来自 B 站接口。
o.bind("SUPER + CTRL + M", "Bilibili 音乐 (cliamp)", {
  tui = os.getenv("HOME") .. "/.local/bin/cliamp-bilibili",
  focus = true,
})

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
