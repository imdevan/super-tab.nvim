local super_tab = require("super-tab")

local function setup_buf(lines, row, ft)
	vim.cmd("enew!")
	vim.bo.expandtab = true
	vim.bo.shiftwidth = 4
	vim.bo.tabstop = 4
	if ft then
		vim.bo.filetype = ft
	else
		vim.bo.commentstring = "-- %s"
		vim.bo.comments = ":--"
	end
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(0, { row, 0 })
end

local function lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

describe("super-tab", function()
	before_each(function()
		super_tab.setup()
	end)

	it("defines commands and no hello world leftovers", function()
		local cmds = vim.api.nvim_get_commands({})
		assert.is_not_nil(cmds.SuperTab)
		assert.is_not_nil(cmds.SuperTabBack)
		assert.is_nil(cmds.HelloWorld)
	end)

	it("maps <M->> and <M-<> in normal and insert mode", function()
		for _, mode in ipairs({ "n", "i" }) do
			assert.are.same(1, vim.fn.mapcheck("<M->>", mode) ~= "" and 1 or 0)
			assert.are.same(1, vim.fn.mapcheck("<M-lt>", mode) ~= "" and 1 or 0)
		end
	end)

	it("does not map keys when keymaps are disabled", function()
		pcall(vim.keymap.del, { "n", "i" }, "<M->>")
		pcall(vim.keymap.del, { "n", "i" }, "<M-lt>")
		super_tab.setup({ keymaps = { enabled = false } })
		assert.are.equal("", vim.fn.mapcheck("<M->>", "n"))
	end)

	it("indents to the context of the line above", function()
		setup_buf({ "some line", "    another line", "third line" }, 3)
		super_tab.super_tab()
		assert.are.same({ "some line", "    another line", "    third line" }, lines())
	end)

	it("indents to the context of the line below", function()
		setup_buf({ "a", "b", "  c" }, 2)
		super_tab.super_tab()
		assert.are.same({ "a", "  b", "  c" }, lines())
	end)

	it("falls back to shiftwidth without context", function()
		setup_buf({ "a", "b", "c" }, 2)
		super_tab.super_tab()
		assert.are.same({ "a", "    b", "c" }, lines())
	end)

	it("skips blank lines when looking for context", function()
		setup_buf({ "  a", "", "b" }, 3)
		super_tab.super_tab()
		assert.are.same({ "  a", "", "  b" }, lines())
	end)

	it("dedents to the context of a neighbor", function()
		setup_buf({ "  a", "        b" }, 2)
		super_tab.super_tab_back()
		assert.are.same({ "  a", "  b" }, lines())
	end)

	it("dedents by shiftwidth without context and stops at zero", function()
		setup_buf({ "      b" }, 1)
		super_tab.super_tab_back()
		assert.are.same({ "  b" }, lines())
		super_tab.super_tab_back()
		assert.are.same({ "b" }, lines())
		super_tab.super_tab_back()
		assert.are.same({ "b" }, lines())
	end)

	it("supports a count", function()
		setup_buf({ "a" }, 1)
		super_tab.super_tab(2)
		assert.are.same({ "        a" }, lines())
	end)

	it("uses tabs when noexpandtab", function()
		setup_buf({ "a" }, 1)
		vim.bo.expandtab = false
		super_tab.super_tab()
		assert.are.same({ "\ta" }, lines())
	end)

	it("tabs within a comment block by a standard tab when nothing is indented", function()
		setup_buf({ "-- some comment", "-- second line", "-- third line" }, 2, "lua")
		super_tab.super_tab()
		assert.are.same({ "-- some comment", "--     second line", "-- third line" }, lines())
		super_tab.super_tab_back()
		assert.are.same({ "-- some comment", "-- second line", "-- third line" }, lines())
	end)

	it("snaps to comment block spacing above or below", function()
		setup_buf({ "  -- a", "  --   b", "  -- c" }, 3, "lua")
		super_tab.super_tab()
		assert.are.same({ "  -- a", "  --   b", "  --   c" }, lines())
	end)

	it("steps by the comment block's own spacing", function()
		setup_buf({ "-- a", "--   b", "--   c" }, 3, "lua")
		super_tab.super_tab()
		assert.are.same({ "-- a", "--   b", "--     c" }, lines())
		super_tab.super_tab_back()
		super_tab.super_tab_back()
		assert.are.same({ "-- a", "--   b", "-- c" }, lines())
	end)

	it("ignores lines outside the comment block", function()
		setup_buf({ "  x", "-- a", "-- b" }, 3, "lua")
		super_tab.super_tab()
		assert.are.same({ "  x", "-- a", "--     b" }, lines())
	end)

	it("works with other languages' comments", function()
		setup_buf({ "# a", "#   b", "# c" }, 3, "python")
		super_tab.super_tab()
		assert.are.same({ "# a", "#   b", "#   c" }, lines())
		setup_buf({ "// a", "// b" }, 2, "c")
		super_tab.super_tab()
		assert.are.same({ "// a", "//     b" }, lines())
	end)

	it("steps by the indent used around the line", function()
		setup_buf({ "a", "  b", "    c", "d" }, 4)
		super_tab.super_tab()
		assert.are.same("    d", lines()[4])
		super_tab.super_tab()
		assert.are.same("      d", lines()[4])
		super_tab.super_tab_back()
		super_tab.super_tab_back()
		assert.are.same("  d", lines()[4])
	end)

	it("keeps the cursor on the same text", function()
		setup_buf({ "abc" }, 1)
		vim.api.nvim_win_set_cursor(0, { 1, 2 })
		super_tab.super_tab()
		assert.are.same({ 1, 6 }, vim.api.nvim_win_get_cursor(0))
	end)

	it("works via the :SuperTab and :SuperTabBack commands", function()
		setup_buf({ "a" }, 1)
		vim.cmd("SuperTab")
		assert.are.same({ "    a" }, lines())
		vim.cmd("SuperTabBack")
		assert.are.same({ "a" }, lines())
	end)

	it("works from insert mode via the keymap", function()
		setup_buf({ "foo" }, 1)
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("A<M->>x<Esc>", true, false, true), "x", false)
		assert.are.same({ "    foox" }, lines())
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("A<M-<>y<Esc>", true, false, true), "x", false)
		assert.are.same({ "fooxy" }, lines())
	end)
end)
