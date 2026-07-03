local M = {}

---@class SuperTabConfig
---@field keymaps      SuperTabKeymaps

---@class SuperTabKeymaps
---@field enabled boolean  master switch for all keymaps

M.defaults = {
	keymaps = {
		enabled = true,
	},
	shadow = {
		auto_attach = true,
	},
}

---@type SuperTabConfig
M.options = vim.tbl_deep_extend("force", {}, M.defaults)

---Merge user opts over defaults and store in M.options
---@param opts? SuperTabConfig
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
