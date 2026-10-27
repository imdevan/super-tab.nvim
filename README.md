# super-tab.nvim

Context-aware line indenting for Neovim. Like `>>` / `<<`, but the indent snaps to the
surrounding lines, and inside comment blocks it indents the comment text instead of the comment.

## Installation

### lazy.nvim

```lua
{
  "imdevan/super-tab.nvim",
  opts = {},
}
```

## Behavior

**SuperTab** steps the current line relative to the lines around it:

1. If the line directly above or below (blank lines skipped) is indented deeper, snap to it.
2. Otherwise step by the indent unit the surrounding lines use (e.g. 2 spaces if nearby lines
   are indented by 2).
3. If no nearby line is indented, step by a standard tab (`shiftwidth`).

```
some line                 some line
    another line    ->        another line
third line                    third line
```

**SuperTabBack** is the mirror image: snap to a shallower neighbor, else step back by the
inferred unit or `shiftwidth` (never below 0).

**Comment blocks**: on a comment line, only the whitespace after the comment leader changes, and
the same rules apply using only the lines of that comment block. Comment leaders come from the
buffer's `commentstring` and `comments` options, so this works in any language.

```lua
-- some comment            -- some comment
--   indented      ->      --   indented
-- third line              --   third line
```

The cursor stays on the same text, and a count is supported in normal mode (`3<M->>`).

## Configuration

```lua
{
  "imdevan/super-tab.nvim",
  opts = {
    keymaps = {
      enabled = true,
      super_tab = "<M->>",
      super_tab_back = "<M-lt>", -- <M-<>
    },
    context_lines = 10, -- lines above/below used to infer the indent step
  },
}
```

## Keymaps

Normal and insert mode:

| Key | Action |
|-----|--------|
| `<M->>` | SuperTab: indent line |
| `<M-<>` | SuperTabBack: dedent line |

Set `keymaps.enabled = false` to disable and define your own mappings:

```lua
vim.keymap.set({ "n", "i" }, "<Tab>", function() require("super-tab").super_tab() end)
vim.keymap.set({ "n", "i" }, "<S-Tab>", function() require("super-tab").super_tab_back() end)
```

## Commands

| Command | Description |
|---------|-------------|
| `:SuperTab [count]` | Indent the current line |
| `:SuperTabBack [count]` | Dedent the current line |

## Running tests

Requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) on your runtime path (or a clone in `vendor/plenary.nvim`).

```bash
just test
```
