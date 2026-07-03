local M = {}

---Setup the plugin with optional user configuration
---@param opts? SuperTabConfig
function M.setup(opts)
	require("super-tab.config").setup(opts)

	vim.api.nvim_create_user_command("SuperTab", function()
		require("super-tab.super_tab").super_tab()
	end, { desc = "Super tab forward" })

	vim.api.nvim_create_user_command("SuperTabBack", function()
		require("super-tab.super_tab").super_tab_back()
	end, { desc = "Super tab back" })

	local cfg = require("super-tab.config").options
	if cfg.keymaps.enabled then
		local map = function(lhs, cmd, desc)
			vim.keymap.set("n", lhs, "<cmd>" .. cmd .. "<cr>", { desc = desc })
			vim.keymap.set("v", lhs, "<cmd>" .. cmd .. "<cr>", { desc = desc })
		end

		map("<M->>", "SuperTab", "Super tab forward")
		map("<M-<>", "SuperTab", "Super tab back")

		-- local ok, wk = pcall(require, "which-key")
		-- if ok then
		-- 	wk.add({ { "<leader>h", group = "Hello" } })
		-- end
	end
end

return M
