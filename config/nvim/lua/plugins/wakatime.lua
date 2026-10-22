return {
	{
		"wakatime/vim-wakatime",
		-- vim-wakatime is a Vimscript plugin that hooks BufEnter/VimEnter/CursorHold
		-- at load time, so it has to be loaded during startup instead of lazily.
		lazy = false,
		-- wakatime-cli 与本机的 api_key 都在 ~/.wakatime 下，插件会自动探测
		-- ~/.wakatime/wakatime-cli，无需额外配置。
	},
}
