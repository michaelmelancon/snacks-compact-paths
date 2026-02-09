-- Final test for the Snacks Compact Paths plugin
-- This test verifies the plugin works correctly with the actual module structure

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
  },
  {
    input = "app/components/ui/button/Button.tsx",
    expected = "app/components/ui/button/Button.tsx",
    description = "React component structure"
  },
  {
    input = "packages/core/src/utils/helpers/validation/email.js",
    expected = "packages/core/src/utils/helpers/V/email.js",
    description = "Monorepo package structure"
  }
}

-- Run tests
print("Running Final Snacks Compact Paths tests...")
print("===========================================")

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
