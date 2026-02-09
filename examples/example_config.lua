-- Example configuration for Snacks Compact Paths

-- Basic configuration
require("snacks-compact-paths").setup({
  min_path_length = 3,
  preserve_dirs = {
    "src", "lib", "include", "test", "tests", "docs", "assets", "public"
  },
  acronym_style = "first",
  enabled = true,
})

-- Advanced configuration for different project types
local function setup_for_java_project()
  require("snacks-compact-paths").setup({
    min_path_length = 2,
    preserve_dirs = {
      "src", "test", "main", "java", "resources", "webapp"
    },
    acronym_style = "vowels", -- Use consonant-based acronyms
    enabled = true,
  })
end

local function setup_for_web_project()
  require("snacks-compact-paths").setup({
    min_path_length = 4,
    preserve_dirs = {
      "src", "public", "assets", "components", "pages", "styles", "utils"
    },
    acronym_style = "first",
    enabled = true,
  })
end

local function setup_for_python_project()
  require("snacks-compact-paths").setup({
    min_path_length = 3,
    preserve_dirs = {
      "src", "tests", "docs", "scripts", "data", "config"
    },
    acronym_style = "first",
    enabled = true,
  })
end

-- Auto-detect project type and configure accordingly
local function auto_configure()
  local cwd = vim.fn.getcwd()
  
  if vim.fn.filereadable(cwd .. "/pom.xml") or vim.fn.filereadable(cwd .. "/build.gradle") then
    setup_for_java_project()
  elseif vim.fn.filereadable(cwd .. "/package.json") then
    setup_for_web_project()
  elseif vim.fn.filereadable(cwd .. "/pyproject.toml") or vim.fn.filereadable(cwd .. "/setup.py") then
    setup_for_python_project()
  else
    -- Default configuration
    require("snacks-compact-paths").setup()
  end
end

-- Call auto-configure when entering a buffer
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = auto_configure,
  once = true,
})
