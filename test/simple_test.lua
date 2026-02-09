-- Simple test for path compaction logic

-- Helper functions
local function should_preserve_segment(segment, preserve_dirs)
  if not segment or segment == "" then
    return true
  end
  
  -- Check against preserve list first
  local lower_segment = segment:lower()
  for _, preserve_dir in ipairs(preserve_dirs) do
    if lower_segment == preserve_dir:lower() then
      return true
    end
  end
  
  -- Single character segments are not automatically preserved
  -- unless they're in the preserve list
  return false
end

local function generate_smart_acronym(segments, style)
  local chars = {}
  
  for _, segment in ipairs(segments) do
    if style == "vowels" then
      local consonants = segment:gsub("[aeiouAEIOU]", "")
      if #consonants > 0 then
        table.insert(chars, consonants:sub(1, 1):upper())
      else
        table.insert(chars, segment:sub(1, 1):upper())
      end
    else
      table.insert(chars, segment:sub(1, 1):upper())
    end
  end
  
  return table.concat(chars, ".")
end

local function create_compacted_path(segments, config)
  local result = {}
  local i = 1
  
  while i <= #segments do
    local segment = segments[i]
    
    -- Always preserve first and last segments
    if i == 1 or i == #segments then
      table.insert(result, segment)
      i = i + 1
    else
      -- Check if this segment should be preserved
      if should_preserve_segment(segment, config.preserve_dirs) then
        table.insert(result, segment)
        i = i + 1
      else
        -- Look for consecutive segments that can be compacted
        local compactable_segments = { segment }
        local j = i + 1
        
        -- Collect consecutive non-preserved segments
        -- For package-like structures, we want to compact even longer segments
        while j < #segments and 
              not should_preserve_segment(segments[j], config.preserve_dirs) do
          table.insert(compactable_segments, segments[j])
          j = j + 1
        end
        
        -- Only compact if we have more than one segment
        if #compactable_segments > 1 then
          local acronym = generate_smart_acronym(compactable_segments, config.acronym_style)
          table.insert(result, acronym)
          i = j
        else
          table.insert(result, segment)
          i = i + 1
        end
      end
    end
  end
  
  return result
end

-- Compact path function
local function compact_path(path, config)
  if not config.enabled or not path or path == "" then
    return path
  end
  
  local parts = {}
  for part in path:gmatch("[^/]+") do
    if part ~= "" then
      table.insert(parts, part)
    end
  end
  
  if #parts <= 2 then
    return path
  end
  
  local compacted_parts = create_compacted_path(parts, config)
  return table.concat(compacted_parts, "/")
end

-- Test configuration
local config = {
  min_path_length = 4, -- Increase to 4 so "com" (3 chars) gets compacted
  preserve_dirs = {
    "src", "lib", "include", "test", "tests", "docs", "assets", "public", "java", "main", "resources"
  },
  acronym_style = "first",
  enabled = true,
}

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

-- Debug function
local function debug_compact_path(path, config)
  print("Debug for: " .. path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    if part ~= "" then
      table.insert(parts, part)
    end
  end
  
  print("Parts: " .. table.concat(parts, ", "))
  
  for i, part in ipairs(parts) do
    local should_preserve = should_preserve_segment(part, config.preserve_dirs)
    local is_short = #part <= config.min_path_length
    print(string.format("  [%d] %s: preserve=%s, short=%s", i, part, should_preserve, is_short))
  end
  
  local result = compact_path(path, config)
  print("Result: " .. result)
  print("---")
  return result
end

-- Run tests
print("Running Snacks Compact Paths tests...")
print("=====================================")

local passed = 0
local total = #test_cases

-- Debug failing test cases
debug_compact_path(test_cases[3].input, config)
debug_compact_path(test_cases[5].input, config)

for i, test_case in ipairs(test_cases) do
  local result = compact_path(test_case.input, config)
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