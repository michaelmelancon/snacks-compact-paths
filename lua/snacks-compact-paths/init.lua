local M = {}
local utils = require("snacks-compact-paths.utils")

local default_config = {
  min_path_length = 4, -- Minimum path length to trigger compaction
  preserve_dirs = {
    "src", "lib", "include", "test", "tests", "docs", "assets", "public", "java", "main", "resources"
  },
  acronym_style = "first", -- "first" or "vowels"
  enabled = true,
  max_depth = 10, -- Maximum depth before forcing compaction
}

local config = vim.tbl_deep_extend("force", {}, default_config)

-- Compact a path by collapsing empty intermediate directories
local function compact_path(path)
  if not config.enabled or not path or path == "" then
    return path
  end
  
  local parts = vim.split(path, "/", { plain = true })
  
  -- Filter out empty parts
  local filtered_parts = {}
  for _, part in ipairs(parts) do
    if part ~= "" then
      table.insert(filtered_parts, part)
    end
  end
  
  if #filtered_parts <= 2 then
    return path -- Don't compact very short paths
  end
  
  -- Use utility function to create compacted path
  local compacted_parts = utils.create_compacted_path(filtered_parts, config)
  
  return table.concat(compacted_parts, "/")
end

-- Hook into Snacks Explorer
local function setup_snacks_integration()
  -- Check if Snacks is available
  local snacks_ok, snacks = pcall(require, "snacks")
  if not snacks_ok then
    vim.notify("Snacks Explorer not found. Please install snacks.nvim first.", vim.log.levels.WARN)
    return
  end
  
  -- Store original functions
  local original_get_file_tree = snacks.get_file_tree
  local original_render_file_tree = snacks.render_file_tree
  
  -- Override get_file_tree to apply compaction
  if original_get_file_tree then
    snacks.get_file_tree = function(opts)
      local tree = original_get_file_tree(opts)
      if tree and config.enabled then
        local function compact_tree_node(node)
          if node.path then
            node.original_path = node.path
            node.path = compact_path(node.path)
            node.display_name = vim.fn.fnamemodify(node.path, ":t")
          end
          if node.children then
            for _, child in ipairs(node.children) do
              compact_tree_node(child)
            end
          end
        end
        compact_tree_node(tree)
      end
      return tree
    end
  end
  
  -- Override render_file_tree to handle compacted paths
  if original_render_file_tree then
    snacks.render_file_tree = function(tree, opts)
      if tree and config.enabled then
        -- Ensure all nodes have compacted paths
        local function ensure_compacted(node)
          if node.original_path and not node.path then
            node.path = compact_path(node.original_path)
            node.display_name = vim.fn.fnamemodify(node.path, ":t")
          end
          if node.children then
            for _, child in ipairs(node.children) do
              ensure_compacted(child)
            end
          end
        end
        ensure_compacted(tree)
      end
      return original_render_file_tree(tree, opts)
    end
  end
end

-- Setup function
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})
  
  -- Set up the integration
  setup_snacks_integration()
  
  -- Create commands
  vim.api.nvim_create_user_command("SnacksCompactPathsToggle", function()
    config.enabled = not config.enabled
    vim.notify("Snacks Compact Paths " .. (config.enabled and "enabled" or "disabled"), vim.log.levels.INFO)
  end, { desc = "Toggle Snacks Compact Paths" })
  
  vim.api.nvim_create_user_command("SnacksCompactPathsRefresh", function()
    -- Trigger a refresh of the file tree
    local snacks_ok, snacks = pcall(require, "snacks")
    if snacks_ok and snacks.refresh then
      snacks.refresh()
    end
  end, { desc = "Refresh Snacks Explorer with compacted paths" })
end

-- Public API
M.compact_path = compact_path
M.setup = M.setup

return M
