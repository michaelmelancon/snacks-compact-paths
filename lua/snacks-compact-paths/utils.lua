local M = {}

-- Check if a path segment should be preserved
function M.should_preserve_segment(segment, preserve_dirs)
  if not segment or segment == "" then
    return true
  end

  local lower_segment = segment:lower()
  for _, preserve_dir in ipairs(preserve_dirs) do
    if lower_segment == preserve_dir:lower() then
      return true
    end
  end

  return false
end

-- Generate an acronym from directory segments
function M.generate_smart_acronym(segments, style)
  local chars = {}

  for _, segment in ipairs(segments) do
    if style == "vowels" then
      local consonants = segment:gsub("[aeiouAEIOU]", "")
      if #consonants > 0 then
        table.insert(chars, consonants:sub(1, 1):lower())
      else
        table.insert(chars, segment:sub(1, 1):lower())
      end
    else
      table.insert(chars, segment:sub(1, 1):lower())
    end
  end

  return table.concat(chars, ".")
end

-- Create a compacted path from segments
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
        -- Collect consecutive non-preserved segments
        local compactable = { segment }
        local j = i + 1

        while j < #segments and
              not M.should_preserve_segment(segments[j], config.preserve_dirs) do
          table.insert(compactable, segments[j])
          j = j + 1
        end

        if #compactable > 1 then
          local acronym = M.generate_smart_acronym(compactable, config.acronym_style)
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
