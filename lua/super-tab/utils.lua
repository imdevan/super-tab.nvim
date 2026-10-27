local M = {}

---Return the content of line n (1-indexed) in the given buffer
---@param bufnr integer
---@param n integer
---@return string
function M.get_line(bufnr, n)
  return vim.api.nvim_buf_get_lines(bufnr, n - 1, n, false)[1] or ""
end

---Return total line count for the given buffer
---@param bufnr integer
---@return integer
function M.line_count(bufnr)
  return vim.api.nvim_buf_line_count(bufnr)
end

---Return the display width of a whitespace string
---@param ws string
---@return integer
function M.width(ws)
  return vim.fn.strdisplaywidth(ws)
end

---Collect line comment leaders for the given buffer, longest first.
---Uses 'commentstring' plus the flag-less / middle parts of 'comments'.
---@param bufnr integer
---@return string[]
function M.comment_leaders(bufnr)
  local seen, leaders = {}, {}
  local function add(l)
    l = vim.trim(l or "")
    if l ~= "" and not seen[l] then
      seen[l] = true
      leaders[#leaders + 1] = l
    end
  end

  local cs = vim.bo[bufnr].commentstring or ""
  local left = cs:match("^(.-)%%s")
  -- Only treat commentstring as a line leader when it has no closing part
  if left and vim.trim(cs:match("%%s(.*)$") or "") == "" then
    add(left)
  end

  for part in (vim.bo[bufnr].comments or ""):gmatch("[^,]+") do
    local flags, leader = part:match("^([^:]*):(.*)$")
    -- skip first-line-only (f), start (s) and end (e) parts
    if flags and not flags:find("[fse]") then
      add(leader)
    end
  end

  table.sort(leaders, function(a, b)
    return #a > #b
  end)
  return leaders
end

return M
