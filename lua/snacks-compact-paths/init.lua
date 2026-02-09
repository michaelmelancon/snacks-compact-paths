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

-- Compact a path by abbreviating non-preserved intermediate directory segments
local function compact_path(path)
  if not config.enabled or not path or path == "" then
    return path
  end

  local parts = vim.split(path, "/", { plain = true })

  local filtered = {}
  for _, part in ipairs(parts) do
    if part ~= "" then
      table.insert(filtered, part)
    end
  end

  if #filtered <= 2 then
    return path
  end

  local compacted = utils.create_compacted_path(filtered, config)
  return table.concat(compacted, "/")
end

-- Integrate with Snacks Explorer by wrapping Snacks.explorer() to inject
-- a transform that compacts grouped directory names (names containing "/").
local function setup_snacks_integration()
  if snacks_wrapped then
    return
  end

  local ok, Snacks = pcall(require, "snacks")
  if not ok or not Snacks then
    -- Snacks not yet loaded; retry once after VimEnter
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        vim.schedule(setup_snacks_integration)
      end,
    })
    return
  end

  if type(Snacks.explorer) ~= "function" then
    return
  end

  snacks_wrapped = true
  local orig_explorer = Snacks.explorer

  Snacks.explorer = function(opts)
    if config.enabled then
      opts = opts or {}
      local orig_transform = opts.transform
      opts.transform = function(item)
        if orig_transform then
          item = orig_transform(item) or item
        end
        if item then
          -- Compact grouped directory names (paths containing "/")
          if item.text and type(item.text) == "string" and item.text:find("/") then
            item.text = compact_path(item.text)
          end
        end
        return item
      end
    end
    return orig_explorer(opts)
  end
end

-- Setup function
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

-- Public API
M.compact_path = compact_path

return M
