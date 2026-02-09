# Installation Guide

## Prerequisites

- Neovim 0.7+
- Snacks Explorer plugin (`stevearc/snacks.nvim`)

## Installation

### Using lazy.nvim

Add this to your Neovim configuration:

```lua
{
  "michaelmelancon/snacks-compact-paths",
  dependencies = { "stevearc/snacks.nvim" },
  config = function()
    require("snacks-compact-paths").setup()
  end,
}
```

### Using packer.nvim

Add this to your Neovim configuration:

```lua
use {
  "michaelmelancon/snacks-compact-paths",
  requires = { "stevearc/snacks.nvim" },
  config = function()
    require("snacks-compact-paths").setup()
  end,
}
```

### Manual Installation

1. Clone this repository to your Neovim plugin directory:
   ```bash
   git clone https://github.com/michaelmelancon/snacks-compact-paths.git ~/.local/share/nvim/site/pack/plugins/start/snacks-compact-paths
   ```

2. Add to your Neovim configuration:
   ```lua
   require("snacks-compact-paths").setup()
   ```

## Configuration

The plugin can be configured by passing a configuration table to the setup function:

```lua
require("snacks-compact-paths").setup({
  min_path_length = 4,        -- Minimum path length to trigger compaction
  preserve_dirs = {           -- Directories to never compact
    "src", "lib", "include", "test", "tests", "docs", "assets", "public", "java", "main", "resources"
  },
  acronym_style = "first",    -- "first" or "vowels" for acronym generation
  enabled = true,             -- Enable/disable the plugin
})
```

## Commands

- `:SnacksCompactPathsToggle` - Toggle the plugin on/off
- `:SnacksCompactPathsRefresh` - Refresh the Snacks Explorer with current settings

## Testing

Run the test suite to verify the plugin works correctly:

```bash
lua test/simple_test.lua
```

All tests should pass, showing 100% success rate.
