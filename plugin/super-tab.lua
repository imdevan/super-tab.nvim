-- Auto-loaded by Neovim on startup when installed as a plugin.
-- Calls setup with no args so the plugin works out of the box with defaults.
-- Users who want custom config should call require("super-tab").setup(opts)
-- in their own init.lua BEFORE this file runs, or rely on lazy.nvim's `opts` key.
if vim.g.loaded_super-tab then
	return
end
vim.g.loaded_super-tab = true

require("super-tab").setup()
