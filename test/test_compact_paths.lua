-- Add current directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local compact_paths = require("snacks-compact-paths")

-- Test cases for path compaction
local test_cases = {
  {
    input = "src/main/java/com/example/myapp/Main.java",
    expected = "src/main/java/c.e.m/Main.java",
    description = "Standard Java package structure"
  },
  {
    input = "project/src/lib/include/test/file.js",
    expected = "project/src/lib/include/test/file.js",
    description = "All directories preserved"
  },
  {
    input = "a/b/c/d/e/f/file.txt",
    expected = "a/b.c.d.e/f/file.txt",
    description = "Multiple short directories"
  },
  {
    input = "src/main/resources/static/css/style.css",
    expected = "src/main/resources/static/css/style.css",
    description = "Long directory names preserved"
  },
  {
    input = "x/y/z/file.py",
    expected = "x.y.z/file.py",
    description = "All short directories compacted"
  }
}

-- Run tests
print("Running Snacks Compact Paths tests...")
print("=====================================")

for i, test_case in ipairs(test_cases) do
  local result = compact_paths.compact_path(test_case.input)
  local passed = result == test_case.expected
  
  print(string.format("Test %d: %s", i, test_case.description))
  print(string.format("  Input:    %s", test_case.input))
  print(string.format("  Expected: %s", test_case.expected))
  print(string.format("  Result:   %s", result))
  print(string.format("  Status:   %s", passed and "PASS" or "FAIL"))
  print()
end
