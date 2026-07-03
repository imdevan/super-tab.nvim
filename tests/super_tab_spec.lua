local super_tab = require("super-tab.super_tab")
local utils = require("super-tab.utils")

describe("super-tab", function()
	local bufnr

	before_each(function()
		bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(0, bufnr)
		vim.bo[bufnr].shiftwidth = 2
		vim.bo[bufnr].tabstop = 2
		vim.bo[bufnr].expandtab = true
		vim.bo[bufnr].commentstring = "// %s"
	end)

	after_each(function()
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("should indent normal lines forward and backward", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "hello" })
		vim.api.nvim_win_set_cursor(0, { 1, 0 })

		super_tab.super_tab()
		assert.are.equal("  hello", utils.get_line(bufnr, 1))

		super_tab.super_tab()
		assert.are.equal("    hello", utils.get_line(bufnr, 1))

		super_tab.super_tab_back()
		assert.are.equal("  hello", utils.get_line(bufnr, 1))

		super_tab.super_tab_back()
		assert.are.equal("hello", utils.get_line(bufnr, 1))
	end)

	it("should align normal lines to the line above", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "    first", "second" })
		vim.api.nvim_win_set_cursor(0, { 2, 0 })

		super_tab.super_tab()
		assert.are.equal("    second", utils.get_line(bufnr, 2))

		super_tab.super_tab()
		assert.are.equal("      second", utils.get_line(bufnr, 2))

		super_tab.super_tab_back()
		assert.are.equal("    second", utils.get_line(bufnr, 2))
	end)

	it("should respect comment syntax when respect_comments is enabled", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "//hello" })
		vim.api.nvim_win_set_cursor(0, { 1, 0 })

		super_tab.super_tab()
		assert.are.equal("//  hello", utils.get_line(bufnr, 1))

		super_tab.super_tab()
		assert.are.equal("//    hello", utils.get_line(bufnr, 1))

		super_tab.super_tab_back()
		assert.are.equal("//  hello", utils.get_line(bufnr, 1))

		super_tab.super_tab_back()
		assert.are.equal("// hello", utils.get_line(bufnr, 1))
	end)

	it("should respect comment syntax with spaces after comment", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "// hello" })
		vim.api.nvim_win_set_cursor(0, { 1, 0 })

		super_tab.super_tab()
		assert.are.equal("//   hello", utils.get_line(bufnr, 1))

		super_tab.super_tab_back()
		assert.are.equal("// hello", utils.get_line(bufnr, 1))
	end)

	it("should respect comment syntax without spaces after comment if commentstring has no space", function()
		vim.bo[bufnr].commentstring = "//%s"
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "//hello" })
		vim.api.nvim_win_set_cursor(0, { 1, 0 })

		super_tab.super_tab()
		assert.are.equal("//  hello", utils.get_line(bufnr, 1))

		super_tab.super_tab_back()
		assert.are.equal("//hello", utils.get_line(bufnr, 1))
	end)

	it("should support visual ranges and preserve relative block integrity", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "line1", "  line2" })

		super_tab.super_tab({ line1 = 1, line2 = 2 })
		assert.are.equal("  line1", utils.get_line(bufnr, 1))
		assert.are.equal("    line2", utils.get_line(bufnr, 2))

		super_tab.super_tab_back({ line1 = 1, line2 = 2 })
		assert.are.equal("line1", utils.get_line(bufnr, 1))
		assert.are.equal("  line2", utils.get_line(bufnr, 2))
	end)
	it("should support visual ranges using active selection when in visual mode", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "line1", "  line2" })
		vim.api.nvim_win_set_cursor(0, { 2, 0 })
		vim.cmd("normal! V")
		vim.api.nvim_win_set_cursor(0, { 1, 0 })

		super_tab.super_tab()
		assert.are.equal("  line1", utils.get_line(bufnr, 1))
		assert.are.equal("    line2", utils.get_line(bufnr, 2))

		super_tab.super_tab_back()
		assert.are.equal("line1", utils.get_line(bufnr, 1))
		assert.are.equal("  line2", utils.get_line(bufnr, 2))

		-- Exit visual mode
		vim.cmd("normal! \x27")
	end)
end)
