local M = {}

---Indent the current line, respecting surrounding lines and comment blocks
---@param count? integer
function M.super_tab(count)
	require("super-tab.indent").run(true, count)
end

---Dedent the current line, respecting surrounding lines and comment blocks
---@param count? integer
function M.super_tab_back(count)
	require("super-tab.indent").run(false, count)
end

---Setup the plugin with optional user configuration
---@param opts? SuperTabConfig
function M.setup(opts)
	require("super-tab.config").setup(opts)

	vim.api.nvim_create_user_command("SuperTab", function(args)
		M.super_tab(args.count > 0 and args.count or 1)
	end, { count = true, desc = "Indent line respecting context" })

	vim.api.nvim_create_user_command("SuperTabBack", function(args)
		M.super_tab_back(args.count > 0 and args.count or 1)
	end, { count = true, desc = "Dedent line respecting context" })

	local cfg = require("super-tab.config").options
	if cfg.keymaps.enabled then
		local map = function(lhs, fn, desc)
			if not lhs or lhs == "" then
				return
			end
			vim.keymap.set({ "n", "i" }, lhs, function()
				fn(vim.v.count1)
			end, { desc = desc })
		end

		map(cfg.keymaps.super_tab, M.super_tab, "SuperTab: indent line")
		map(cfg.keymaps.super_tab_back, M.super_tab_back, "SuperTab: dedent line")
	end
end

return M
