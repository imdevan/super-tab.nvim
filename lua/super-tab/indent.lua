local utils = require("super-tab.utils")

local M = {}

---@class SuperTabLineInfo
---@field blank   boolean  line has no content
---@field leader? string   comment leader when the line is a comment
---@field outer   string   whitespace before the comment leader (comment lines only)
---@field ws      string   the indentation whitespace super-tab operates on
---@field ws_col  integer  0-indexed byte column where `ws` starts
---@field width   integer  display width of `ws`

---Split a line into the part super-tab leaves alone and the indentation it edits.
---For comment lines the indentation is the whitespace after the leader.
---@param line    string
---@param leaders string[]
---@return SuperTabLineInfo
function M.parse(line, leaders)
	local outer = line:match("^%s*")
	local rest = line:sub(#outer + 1)
	for _, leader in ipairs(leaders) do
		if rest:sub(1, #leader) == leader then
			local ws = rest:sub(#leader + 1):match("^%s*")
			return {
				blank = #outer + #leader + #ws == #line,
				leader = leader,
				outer = outer,
				ws = ws,
				ws_col = #outer + #leader,
				width = utils.width(ws),
			}
		end
	end
	return {
		blank = rest == "",
		outer = "",
		ws = outer,
		ws_col = 0,
		width = utils.width(outer),
	}
end

---Collect context widths in direction `dir` (-1 up, +1 down), nearest first.
---Code lines use non-blank lines (comment lines count by their outer indent).
---Comment lines only use their own comment block (same leader, same outer indent).
---@return integer[]
local function context(bufnr, row, dir, cur, leaders, max)
	local widths = {}
	local last = utils.line_count(bufnr)
	local n = row + dir
	while n >= 1 and n <= last and #widths < max do
		local info = M.parse(utils.get_line(bufnr, n), leaders)
		if cur.leader then
			if info.leader ~= cur.leader or info.outer ~= cur.outer then
				break
			end
			if not info.blank then
				widths[#widths + 1] = info.width
			end
		elseif not info.blank then
			widths[#widths + 1] = info.leader and utils.width(info.outer) or info.width
		end
		n = n + dir
	end
	return widths
end

---Infer the indent step used by the surrounding lines: the smallest gap
---between distinct indent widths. Returns nil when nothing is indented
---relative to anything else.
---@param widths integer[]
---@return integer?
function M.infer_step(widths)
	local sorted = vim.deepcopy(widths)
	table.sort(sorted)
	local step
	for i = 2, #sorted do
		local gap = sorted[i] - sorted[i - 1]
		if gap > 0 and (not step or gap < step) then
			step = gap
		end
	end
	return step
end

---Compute the target indent width.
---Forward: nearest neighbor indent deeper than current, else current + step.
---Back:    nearest neighbor indent shallower than current, else current - step.
---@param cur       integer
---@param neighbors integer[]  indent widths of the lines directly above/below
---@param step      integer
---@param forward   boolean
---@return integer
function M.target_width(cur, neighbors, step, forward)
	local best
	for _, w in ipairs(neighbors) do
		if forward and w > cur and (not best or w < best) then
			best = w
		elseif not forward and w < cur and (not best or w > best) then
			best = w
		end
	end
	if best then
		return best
	end
	if forward then
		return cur + step
	end
	return math.max(cur - step, 0)
end

---Build an indentation string of the given display width.
---@param width     integer
---@param use_tabs  boolean
---@param tabstop   integer
---@return string
local function make_ws(width, use_tabs, tabstop)
	if use_tabs and tabstop > 0 then
		return string.rep("\t", math.floor(width / tabstop)) .. string.rep(" ", width % tabstop)
	end
	return string.rep(" ", width)
end

---Shift the current line one super-tab step.
---@param forward boolean  true for SuperTab, false for SuperTabBack
function M.shift(forward)
	local cfg = require("super-tab.config").options
	local bufnr = vim.api.nvim_get_current_buf()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local leaders = utils.comment_leaders(bufnr)
	local cur = M.parse(utils.get_line(bufnr, row), leaders)

	local max = cfg.context_lines
	local above = context(bufnr, row, -1, cur, leaders, max)
	local below = context(bufnr, row, 1, cur, leaders, max)

	local neighbors = vim.list_extend({ above[1] }, { below[1] })
	local all = vim.list_extend(vim.list_extend({ cur.width }, above), below)
	local step = M.infer_step(all) or vim.fn.shiftwidth()
	local target = M.target_width(cur.width, neighbors, step, forward)
	if target == cur.width then
		return
	end

	local new_ws
	if cur.leader then
		new_ws = string.rep(" ", target)
	else
		new_ws = make_ws(target, not vim.bo[bufnr].expandtab, vim.bo[bufnr].tabstop)
	end

	local ws_end = cur.ws_col + #cur.ws
	vim.api.nvim_buf_set_text(bufnr, row - 1, cur.ws_col, row - 1, ws_end, { new_ws })

	-- keep the cursor on the same text; if it sat inside the indent, land on the content
	if col >= ws_end then
		col = col + #new_ws - #cur.ws
	elseif col > cur.ws_col or vim.api.nvim_get_mode().mode == "n" then
		col = cur.ws_col + #new_ws
	end
	vim.api.nvim_win_set_cursor(0, { row, col })
end

---Run `shift` `count` times
---@param forward boolean
---@param count?  integer
function M.run(forward, count)
	for _ = 1, math.max(count or 1, 1) do
		M.shift(forward)
	end
end

return M
