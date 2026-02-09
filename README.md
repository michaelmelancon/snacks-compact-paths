# Snacks Compact Paths

A Neovim plugin for Snacks Explorer that collapses empty folder paths into single character acronyms, similar to IntelliJ's compacted package view.

## Features

- Collapses empty intermediate directories into single character acronyms
- Configurable minimum path length for compaction
- Preserves important directory names
- Integrates seamlessly with Snacks Explorer
- Customizable acronym generation

## Installation

Using lazy.nvim:
```lua
{
  "michaelmelancon/snacks-compact-paths",
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("snacks-compact-paths").setup()
  end,
}
```

## Configuration

```lua
require("snacks-compact-paths").setup({
  min_path_length = 3,        -- Minimum path length to trigger compaction
  preserve_dirs = {           -- Directories to never compact
    "src", "lib", "include", "test", "tests"
  },
  acronym_style = "first",    -- "first" or "vowels" for acronym generation
  enabled = true,             -- Enable/disable the plugin
})
```

## Usage

The plugin automatically integrates with Snacks Explorer. No additional commands are needed - it works transparently with the existing file tree.

## Example

Before:
```
project/
├── src/
│   └── main/
│       └── java/
│           └── com/
│               └── example/
│                   └── myapp/
│                       └── Main.java
```

After:
```
project/
├── src/
│   └── main/
│       └── java/
│           └── c.e.m/
│               └── Main.java
```
