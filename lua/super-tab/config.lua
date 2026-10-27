local M = {}

---@class SuperTabConfig
---@field keymaps      SuperTabKeymaps
---@field context_lines integer  how many non-blank lines above/below to inspect for the indent step

---@class SuperTabKeymaps
---@field enabled        boolean  master switch for all keymaps
---@field super_tab      string   lhs for SuperTab (normal + insert)
---@field super_tab_back string   lhs for SuperTabBack (normal + insert)

M.defaults = {
  keymaps = {
    enabled = true,
    super_tab = "<M-.>",
    super_tab_back = "<M-,>",
  },
  context_lines = 10,
}

---@type SuperTabConfig
M.options = vim.tbl_deep_extend("force", {}, M.defaults)

---Merge user opts over defaults and store in M.options
---@param opts? SuperTabConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
