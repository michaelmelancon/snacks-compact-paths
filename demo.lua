-- Demo script for Snacks Compact Paths
-- This shows the plugin in action with various path examples

-- Add current directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for standalone execution
vim = {
  tbl_deep_extend = function(behavior, target, ...)
    local result = {}
    for k, v in pairs(target) do
      result[k] = v
    end
    for _, source in ipairs({...}) do
      for k, v in pairs(source) do
        if type(v) == "table" and type(result[k]) == "table" then
          result[k] = vim.tbl_deep_extend(behavior, result[k], v)
        else
          result[k] = v
        end
      end
    end
    return result
  end,
  split = function(str, pattern, opts)
    local result = {}
    for part in str:gmatch("[^" .. pattern .. "]+") do
      table.insert(result, part)
    end
    return result
  end,
  fn = {
    fnamemodify = function(path, modifier)
      if modifier == ":t" then
        return path:match("([^/]+)$") or path
      end
      return path
    end
  },
  log = {
    levels = {
      WARN = 2,
      INFO = 1
    }
  },
  notify = function(msg, level)
    print("NOTIFY: " .. msg)
  end,
  api = {
    nvim_create_user_command = function(name, callback, opts)
      print("Created command: " .. name)
    end,
    nvim_create_autocmd = function(event, opts)
      -- no-op in demo
    end
  }
}

local compact_paths = require("snacks-compact-paths")

-- Demo configuration
local config = {
  min_path_length = 4,
  preserve_dirs = {
    "src", "lib", "include", "test", "tests", "docs", "assets", "public", "java", "main", "resources"
  },
  acronym_style = "first",
  enabled = true,
}

-- Setup the plugin
compact_paths.setup(config)

-- Demo paths
local demo_paths = {
  "src/main/java/com/example/myapp/Main.java",
  "src/main/java/org/springframework/boot/autoconfigure/Application.java",
  "app/components/ui/button/Button.tsx",
  "packages/core/src/utils/helpers/validation/email.js",
  "project/src/lib/include/test/file.js",
  "a/b/c/d/e/f/g/h/i/j/file.txt",
  "src/main/resources/static/css/style.css",
  "x/y/z/file.py"
}

print("Snacks Compact Paths Demo")
print("========================")
print()

for i, path in ipairs(demo_paths) do
  local compacted = compact_paths.compact_path(path)
  print(string.format("%d. %s", i, path))
  print(string.format("   → %s", compacted))
  print()
end

print("The plugin automatically compacts empty intermediate directories")
print("into single character acronyms, similar to IntelliJ's compacted package view.")
print()
print("Configuration options:")
print("- min_path_length: " .. config.min_path_length)
print("- preserve_dirs: " .. table.concat(config.preserve_dirs, ", "))
print("- acronym_style: " .. config.acronym_style)
print("- enabled: " .. tostring(config.enabled))
