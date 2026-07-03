local M = {}

---Setup the plugin with optional user configuration
---@param opts? SuperTabConfig
function M.setup(opts)
	require("super-tab.config").setup(opts)

	vim.api.nvim_create_user_command("HelloWorld", function()
		require("super-tab.hello_world").hello_world()
	end, { desc = "Print Hello World at cursor" })

	local cfg = require("super-tab.config").options
	if cfg.keymaps.enabled then
		local map = function(lhs, cmd, desc)
			vim.keymap.set("n", lhs, "<cmd>" .. cmd .. "<cr>", { desc = desc })
		end

		map("<leader>hw", "HelloWorld", "Print 'Hello World'")

		local ok, wk = pcall(require, "which-key")
		if ok then
			wk.add({ { "<leader>h", group = "Hello" } })
		end
	end
end

return M
