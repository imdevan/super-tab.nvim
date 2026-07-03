local M = {}

local utils = require("super-tab.utils")
local config = require("super-tab.config")

-- Get comment info: raw_prefix, base_space
local function get_comment_info()
	local commentstring = vim.bo.commentstring
	if not commentstring or commentstring == "" then
		return nil
	end
	local prefix, suffix = commentstring:match("^([^%%]*)%%s(.*)$")
	if not prefix then
		return nil
	end
	local raw_prefix = vim.trim(prefix)
	if raw_prefix == "" then
		return nil
	end
	-- Get the trailing space of the prefix if any
	local base_space = prefix:match("%s+$") or ""
	return raw_prefix, base_space
end

-- Parse a line into comment info and code content
local function parse_line(line)
	local respect_comments = config.options.respect_comments
	if respect_comments == nil then
		respect_comments = true
	end

	if respect_comments then
		local raw_prefix, base_space = get_comment_info()
		if raw_prefix then
			local escaped_prefix = vim.pesc(raw_prefix)
			local leading_ws, comment_char, rest = line:match("^(%s*)(" .. escaped_prefix .. ")(.*)$")
			if leading_ws then
				local comment_ws, code = rest:match("^(%s*)(.*)$")
				local actual_base = ""
				local code_indent = ""
				if #base_space > 0 and comment_ws:sub(1, #base_space) == base_space then
					actual_base = base_space
					code_indent = comment_ws:sub(#base_space + 1)
				else
					code_indent = comment_ws
				end
				return {
					is_comment = true,
					prefix_part = leading_ws .. comment_char,
					base_space = actual_base,
					indent_part = code_indent,
					content_part = code,
				}
			end
		end
	end

	local indent_part, content_part = line:match("^(%s*)(.*)$")
	return {
		is_comment = false,
		prefix_part = "",
		base_space = "",
		indent_part = indent_part,
		content_part = content_part,
	}
end

-- Generate indent string of target width using expandtab and tabstop
local function make_indent_string(width)
	local expandtab = vim.bo.expandtab
	local tabstop = vim.bo.tabstop
	if expandtab then
		return string.rep(" ", width)
	else
		local num_tabs = math.floor(width / tabstop)
		local num_spaces = width % tabstop
		return string.rep("\t", num_tabs) .. string.rep(" ", num_spaces)
	end
end

-- Process a single line for SuperTab (forward)
local function super_tab_line(bufnr, lnum)
	local line = utils.get_line(bufnr, lnum)
	if line == "" then
		local D_above = 0
		if lnum > 1 then
			local above_parsed = parse_line(utils.get_line(bufnr, lnum - 1))
			D_above = vim.fn.strdisplaywidth(above_parsed.indent_part)
		end
		local shiftwidth = vim.fn.shiftwidth()
		local new_depth = D_above > 0 and D_above or shiftwidth
		utils.set_line(bufnr, lnum, make_indent_string(new_depth))
		return
	end

	local parsed = parse_line(line)
	local D_curr = vim.fn.strdisplaywidth(parsed.indent_part)
	local D_above = 0
	if lnum > 1 then
		local above_parsed = parse_line(utils.get_line(bufnr, lnum - 1))
		D_above = vim.fn.strdisplaywidth(above_parsed.indent_part)
	end

	local shiftwidth = vim.fn.shiftwidth()
	local new_depth
	if lnum > 1 and D_curr < D_above then
		new_depth = D_above
	else
		new_depth = D_curr + shiftwidth
	end

	local new_indent_str = make_indent_string(new_depth)
	local new_line
	if parsed.is_comment then
		new_line = parsed.prefix_part .. parsed.base_space .. new_indent_str .. parsed.content_part
	else
		new_line = new_indent_str .. parsed.content_part
	end
	utils.set_line(bufnr, lnum, new_line)
end

-- Process a single line for SuperTabBack
local function super_tab_back_line(bufnr, lnum)
	local line = utils.get_line(bufnr, lnum)
	if line == "" then
		return
	end

	local parsed = parse_line(line)
	local D_curr = vim.fn.strdisplaywidth(parsed.indent_part)
	local D_above = 0
	if lnum > 1 then
		local above_parsed = parse_line(utils.get_line(bufnr, lnum - 1))
		D_above = vim.fn.strdisplaywidth(above_parsed.indent_part)
	end

	local shiftwidth = vim.fn.shiftwidth()
	local new_depth
	if lnum > 1 and D_curr > D_above then
		new_depth = D_above
	else
		new_depth = math.max(0, D_curr - shiftwidth)
	end

	local new_indent_str = make_indent_string(new_depth)
	local new_line
	if parsed.is_comment then
		new_line = parsed.prefix_part .. parsed.base_space .. new_indent_str .. parsed.content_part
	else
		new_line = new_indent_str .. parsed.content_part
	end
	utils.set_line(bufnr, lnum, new_line)
end

-- Apply a uniform shift to a line
local function shift_line(bufnr, lnum, shift)
	local line = utils.get_line(bufnr, lnum)
	if line == "" then
		if shift > 0 then
			utils.set_line(bufnr, lnum, make_indent_string(shift))
		end
		return
	end

	local parsed = parse_line(line)
	local d = vim.fn.strdisplaywidth(parsed.indent_part)
	local new_d = math.max(0, d + shift)

	local new_indent_str = make_indent_string(new_d)
	local new_line
	if parsed.is_comment then
		new_line = parsed.prefix_part .. parsed.base_space .. new_indent_str .. parsed.content_part
	else
		new_line = new_indent_str .. parsed.content_part
	end
	utils.set_line(bufnr, lnum, new_line)
end

-- Resolve the target line range based on mode and options
local function get_range(opts)
	local mode = vim.api.nvim_get_mode().mode
	if mode:match("[vV]") then
		local start_line = vim.fn.line("v")
		local end_line = vim.fn.line(".")
		if start_line > end_line then
			return end_line, start_line
		else
			return start_line, end_line
		end
	elseif opts and opts.line1 and opts.line2 then
		return opts.line1, opts.line2
	else
		local cursor_line = utils.cursor_line()
		return cursor_line, cursor_line
	end
end

function M.super_tab(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local start_line, end_line = get_range(opts)

	if start_line == end_line then
		super_tab_line(bufnr, start_line)
	else
		-- Multiline relative shift
		local first_line = utils.get_line(bufnr, start_line)
		local parsed = parse_line(first_line)
		local D_curr = vim.fn.strdisplaywidth(parsed.indent_part)
		local D_above = 0
		if start_line > 1 then
			local above_parsed = parse_line(utils.get_line(bufnr, start_line - 1))
			D_above = vim.fn.strdisplaywidth(above_parsed.indent_part)
		end

		local shiftwidth = vim.fn.shiftwidth()
		local target_depth
		if start_line > 1 and D_curr < D_above then
			target_depth = D_above
		else
			target_depth = D_curr + shiftwidth
		end

		local shift = target_depth - D_curr
		for lnum = start_line, end_line do
			shift_line(bufnr, lnum, shift)
		end
	end
end

function M.super_tab_back(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local start_line, end_line = get_range(opts)

	if start_line == end_line then
		super_tab_back_line(bufnr, start_line)
	else
		-- Multiline relative shift
		local first_line = utils.get_line(bufnr, start_line)
		local parsed = parse_line(first_line)
		local D_curr = vim.fn.strdisplaywidth(parsed.indent_part)
		local D_above = 0
		if start_line > 1 then
			local above_parsed = parse_line(utils.get_line(bufnr, start_line - 1))
			D_above = vim.fn.strdisplaywidth(above_parsed.indent_part)
		end

		local shiftwidth = vim.fn.shiftwidth()
		local target_depth
		if start_line > 1 and D_curr > D_above then
			target_depth = D_above
		else
			target_depth = math.max(0, D_curr - shiftwidth)
		end

		local shift = target_depth - D_curr
		for lnum = start_line, end_line do
			shift_line(bufnr, lnum, shift)
		end
	end
end

return M
