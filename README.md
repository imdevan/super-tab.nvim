# super-tab.nvim

A context-aware Neovim indentation plugin that improves standard code tabbing.

## Features

- **Standard & Relative Indentation**: Indents or outdents the entire line (similar to `>>` / `<<`) based on standard buffer settings (`shiftwidth`, `tabstop`, `expandtab`).
- **Line-Above Alignment**: Automatically aligns the current line's indentation to match the line above if the current line is less indented (forward) or more indented (backward).
- **Comment-Aware Tabbing**: Keeps comment characters (e.g. `//`, `#`) in their exact horizontal position and indents/outdents the code *after* the comment.
- **Relative Multiline Block Tabbing**: When tabbing a visual selection of multiple lines, `super-tab` shifts all lines by the same relative amount to preserve the block's internal indentation structure (integrity).

## Installation

### lazy.nvim

```lua
{
  "imdevan/super-tab.nvim",
  opts = {},
}
```

## Configuration

Default options:

```lua
{
  "imdevan/super-tab.nvim",
  opts = {
    keymaps = {
      enabled = true, -- Master switch for default keymaps
    },
    respect_comments = true, -- Use commentstring to indent code inside comments
  },
}
```

## Default Keymaps

| Key | Mode | Command | Action |
|-----|------|---------|--------|
| `<M->>` / `<M-gt>` | Normal, Visual | `SuperTab` | Indent / Align Forward |
| `<M-<>` / `<M-lt>` | Normal, Visual | `SuperTabBack` | Outdent / Align Backward |

*Note: Both `<M->>` / `<M-<>` and `<M-gt>` / `<M-lt>` are mapped to ensure compatibility across all terminal emulators.*

Set `keymaps.enabled = false` to disable and define your own mappings:

```lua
{
  "imdevan/super-tab.nvim",
  opts = { keymaps = { enabled = false } },
  config = function(_, opts)
    require("super-tab").setup(opts)
    vim.keymap.set("n", "<Tab>", "<cmd>SuperTab<cr>")
    vim.keymap.set("n", "<S-Tab>", "<cmd>SuperTabBack<cr>")
  end,
}
```

## Commands

| Command | Description |
|---------|-------------|
| `SuperTab` | Indents / aligns the current line or visual selection forward |
| `SuperTabBack` | Outdents / aligns the current line or visual selection backward |

## Development / test

Requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) on your runtime path.
Just optional but recommended for convince 

```bash
just test       # run in tests in headless nvim instance
just install    # install local copy
just reinstall  # uninstall and reinstalllocal copy
```
