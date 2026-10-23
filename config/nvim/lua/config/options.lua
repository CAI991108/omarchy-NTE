-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = false

-- Keep transient Vim backups out of the project/cwd ("." is the default first
-- entry in backupdir). Neovim's state dir is the canonical place, next to
-- swap/ and undo/. Config snapshots live in the sibling "backups/" directory.
vim.opt.backupdir = vim.fn.stdpath("state") .. "/backup//"
