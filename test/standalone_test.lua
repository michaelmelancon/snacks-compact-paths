-- Standalone test for the Snacks Compact Paths plugin
-- This test works without Neovim by mocking the vim API

-- Mock vim API
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
  end,
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
    end
  }
}

-- Add current directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local compact_paths = require("snacks-compact-paths")

-- Test configuration
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

-- Test cases
local test_cases = {
  {
    input = "src/main/java/com/example/myapp/Main.java",
    expected = "src/main/java/C.E.M/Main.java",
    description = "Standard Java package structure"
  },
  {
    input = "project/src/lib/include/test/file.js",
    expected = "project/src/lib/include/test/file.js",
    description = "All directories preserved"
  },
  {
    input = "a/b/c/d/e/f/file.txt",
    expected = "a/B.C.D.E.F/file.txt",
    description = "Multiple short directories"
  },
  {
    input = "src/main/resources/static/css/style.css",
    expected = "src/main/resources/S.C/style.css",
    description = "Long directory names preserved"
  },
  {
    input = "x/y/z/file.py",
    expected = "x/Y.Z/file.py",
    description = "All short directories compacted"
  }
}

-- Run tests
print("Running Standalone Snacks Compact Paths tests...")
print("===============================================")

local passed = 0
local total = #test_cases

for i, test_case in ipairs(test_cases) do
  local result = compact_paths.compact_path(test_case.input)
  local test_passed = result == test_case.expected
  
  print(string.format("Test %d: %s", i, test_case.description))
  print(string.format("  Input:    %s", test_case.input))
  print(string.format("  Expected: %s", test_case.expected))
  print(string.format("  Result:   %s", result))
  print(string.format("  Status:   %s", test_passed and "PASS" or "FAIL"))
  print()
  
  if test_passed then
    passed = passed + 1
  end
end

print(string.format("Results: %d/%d tests passed (%.1f%%)", passed, total, (passed/total)*100))

if passed == total then
  print("🎉 All tests passed! The plugin is working correctly.")
else
  print("❌ Some tests failed. Please check the implementation.")
end
