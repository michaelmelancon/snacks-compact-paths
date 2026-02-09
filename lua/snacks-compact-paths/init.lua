local M = {}
local utils = require("snacks-compact-paths.utils")

local default_config = {
  preserve_dirs = {
    "src", "lib", "include", "test", "tests", "docs",
    "assets", "public", "java", "main", "resources",
  },
  acronym_style = "first", -- "first" or "vowels"
  enabled = true,
}

local config = vim.tbl_deep_extend("force", {}, default_config)
local snacks_wrapped = false

local function basename(filepath)
  return vim.fn.fnamemodify(filepath, ":t")
end

local function is_preserved(name)
  return utils.should_preserve_segment(name, config.preserve_dirs)
end

-- Auto-expand a freshly opened tree node through an empty directory chain.
-- A node is "empty" if its only visible child is a single directory.
-- We open that child and recurse until the chain ends.
-- Only called on nodes that are open but NOT yet expanded (freshly opened),
-- so it won't re-open directories the user just closed.
local function auto_expand_from_node(Tree, node, filter_opts)
  if not node.dir or not node.open then return end
  if node.expanded then return end

  Tree:expand(node)

  local visible_dirs = {}
  local total_visible = 0
  for _, child in pairs(node.children) do
    local visible = true
    if child.hidden and not (filter_opts and filter_opts.hidden) then
      visible = false
    end
    if visible then
      total_visible = total_visible + 1
      if child.dir then
        table.insert(visible_dirs, child)
      end
    end
  end

  -- Empty directory: exactly 1 visible child and it's a directory
  if total_visible == 1 and #visible_dirs == 1 then
    local child = visible_dirs[1]
    child.open = true
    -- Recurse: child is freshly open (not yet expanded)
    auto_expand_from_node(Tree, child, filter_opts)
  end
end

-- Walk the tree looking for freshly opened nodes (open but not expanded)
-- and auto-expand them through empty directory chains.
local function auto_expand_tree(cwd, filter_opts)
  local ok, Tree = pcall(require, "snacks.explorer.tree")
  if not ok or not Tree then return end

  local root = Tree:node(cwd)
  if not root then return end

  local function visit(node)
    if not node.dir or not node.open then return end

    if not node.expanded then
      -- Freshly opened node: auto-expand through empty chain
      auto_expand_from_node(Tree, node, filter_opts)
    else
      -- Already expanded: recurse into open children to find fresh ones
      for _, child in pairs(node.children) do
        if child.dir and child.open then
          visit(child)
        end
      end
    end
  end

  visit(root)
end

-- Detect single-child directory chains and merge them into compact items.
-- A directory is compactable only if it's an "empty folder": its sole child
-- is another directory (no files). The chain is merged into one item with
-- a compact acronym name (e.g. "c.e.m").
local function compact_items(items)
  -- Build a map of parent -> list of children
  local children_of = {}
  for _, item in ipairs(items) do
    if item.parent then
      if not children_of[item.parent] then
        children_of[item.parent] = {}
      end
      table.insert(children_of[item.parent], item)
    end
  end

  -- A directory is compactable if it's a non-root, non-preserved directory
  -- whose only child is a single directory (empty folder).
  local function is_compactable(item)
    if not item or not item.dir then return false end
    if not item.parent then return false end
    if is_preserved(basename(item.file)) then return false end
    local kids = children_of[item]
    return kids ~= nil and #kids == 1 and kids[1].dir
  end

  local skip = {} -- items to remove from output (intermediate chain members)

  for _, item in ipairs(items) do
    if is_compactable(item) and not skip[item] then
      -- Only process chain heads: compactable items whose parent is NOT
      -- itself a compactable item (or whose parent was already skipped).
      local parent_compactable = item.parent
        and is_compactable(item.parent)
        and not skip[item.parent]
      if not parent_compactable then
        -- Build the chain by following single-child directories
        local chain = { item }
        local current = item
        while is_compactable(current) do
          local child = children_of[current][1]
          if child.dir and not is_preserved(basename(child.file)) then
            table.insert(chain, child)
            current = child
          else
            break
          end
        end

        if #chain >= 2 then
          -- Generate compact name from all chain segment names
          local names = {}
          for _, c in ipairs(chain) do
            table.insert(names, basename(c.file))
          end

          local head = chain[1]
          local tail = chain[#chain]

          -- Acronym the leading segments, keep the last dir name in full
          -- e.g. component/agent/version -> c.a.version
          local leading = {}
          for i = 1, #names - 1 do
            table.insert(leading, names[i])
          end
          head._compact_name = utils.generate_smart_acronym(leading, config.acronym_style)
            .. "." .. names[#names]
          -- Point the head at the tail's path so toggle/navigation works
          head.file = tail.file
          head.text = tail.file
          head.open = tail.open

          -- Reparent: children of the tail become children of the head
          local tail_kids = children_of[tail]
          if tail_kids then
            for _, kid in ipairs(tail_kids) do
              kid.parent = head
            end
          end
          children_of[head] = tail_kids

          -- Mark intermediate and tail items for removal
          for i = 2, #chain do
            skip[chain[i]] = true
          end
        end
      end
    end
  end

  -- Rebuild the item list without skipped items
  local result = {}
  for _, item in ipairs(items) do
    if not skip[item] then
      table.insert(result, item)
    end
  end
  return result
end

local function setup_snacks_integration()
  if snacks_wrapped then return end

  -- Wrap the explorer finder in snacks.picker.source.explorer
  local ok_source, explorer_source = pcall(require, "snacks.picker.source.explorer")
  if not ok_source or not explorer_source or not explorer_source.explorer then
    -- Module not available yet; retry after VimEnter
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        vim.schedule(setup_snacks_integration)
      end,
    })
    return
  end

  snacks_wrapped = true

  local orig_explorer = explorer_source.explorer
  explorer_source.explorer = function(opts, ctx)
    local orig_fn = orig_explorer(opts, ctx)
    if not config.enabled then
      return orig_fn
    end

    -- Skip compaction during search/filter mode (async finder)
    local searching = false
    if ctx and ctx.filter then
      local ok, empty = pcall(function() return ctx.filter:is_empty() end)
      if ok then
        searching = not empty
      end
    end
    if searching then
      return orig_fn
    end

    return function(cb)
      -- Auto-expand empty directory chains before the tree walk.
      -- Only targets freshly opened nodes (open but not yet expanded),
      -- so it won't undo a user's close action.
      if ctx and ctx.filter then
        auto_expand_tree(ctx.filter.cwd, opts)
      end

      -- Buffer all items from the tree walk
      local all_items = {}
      orig_fn(function(item)
        table.insert(all_items, item)
      end)

      -- Compact chains and emit
      local compacted = compact_items(all_items)
      for _, item in ipairs(compacted) do
        cb(item)
      end
    end
  end

  -- Patch Format.filename to display _compact_name instead of the basename
  local ok_fmt, Format = pcall(require, "snacks.picker.format")
  if ok_fmt and Format and Format.filename then
    local orig_filename = Format.filename
    Format.filename = function(item, picker, ...)
      if item._compact_name then
        -- Temporarily swap item.file so fnamemodify(:t) returns the compact name
        local real_file = item.file
        local parent_dir = vim.fn.fnamemodify(real_file, ":h")
        item.file = parent_dir .. "/" .. item._compact_name
        item._path = nil -- invalidate cached path
        local ret = orig_filename(item, picker, ...)
        item.file = real_file
        item._path = nil
        return ret
      end
      return orig_filename(item, picker, ...)
    end
  end
end

function M.setup(user_config)
  M._configured = true
  config = vim.tbl_deep_extend("force", default_config, user_config or {})

  setup_snacks_integration()

  vim.api.nvim_create_user_command("SnacksCompactPathsToggle", function()
    config.enabled = not config.enabled
    vim.notify(
      "Snacks Compact Paths " .. (config.enabled and "enabled" or "disabled"),
      vim.log.levels.INFO
    )
  end, { desc = "Toggle Snacks Compact Paths" })
end

M.compact_path = function(path)
  if not config.enabled or not path or path == "" then return path end
  local parts = vim.split(path, "/", { plain = true })
  local filtered = {}
  for _, part in ipairs(parts) do
    if part ~= "" then table.insert(filtered, part) end
  end
  if #filtered <= 2 then return path end
  local compacted = utils.create_compacted_path(filtered, config)
  return table.concat(compacted, "/")
end

return M
