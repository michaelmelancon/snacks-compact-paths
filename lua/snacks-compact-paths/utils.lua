local M = {}

-- Utility functions for the Snacks Compact Paths plugin

-- Check if a path segment should be preserved
function M.should_preserve_segment(segment, preserve_dirs)
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

-- Generate a more sophisticated acronym
function M.generate_smart_acronym(segments, style)
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

-- Check if a directory is likely to be empty (heuristic)
function M.is_likely_empty_dir(path)
  -- This is a heuristic - in a real implementation, you might want to
  -- actually check if the directory is empty
  local basename = vim.fn.fnamemodify(path, ":t")
  
  -- Common empty directory patterns
  local empty_patterns = {
    "^[a-z]$", -- Single letter directories
    "^[a-z][a-z]$", -- Two letter directories
    "^[a-z]%.[a-z]$", -- Single letter with extension pattern
  }
  
  for _, pattern in ipairs(empty_patterns) do
    if basename:match(pattern) then
      return true
    end
  end
  
  return false
end

-- Get the depth of a path
function M.get_path_depth(path)
  local parts = vim.split(path, "/", { plain = true })
  return #parts
end

-- Check if a path is too deep (should be compacted)
function M.is_path_too_deep(path, max_depth)
  return M.get_path_depth(path) > max_depth
end

-- Create a compacted path with better logic
function M.create_compacted_path(segments, config)
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
      if M.should_preserve_segment(segment, config.preserve_dirs) then
        table.insert(result, segment)
        i = i + 1
      else
        -- Look for consecutive segments that can be compacted
        local compactable_segments = { segment }
        local j = i + 1
        
        while j < #segments and 
              not M.should_preserve_segment(segments[j], config.preserve_dirs) do
          table.insert(compactable_segments, segments[j])
          j = j + 1
        end
        
        if #compactable_segments > 1 then
          -- Create acronym from compactable segments
          local acronym = M.generate_smart_acronym(compactable_segments, config.acronym_style)
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

return M
