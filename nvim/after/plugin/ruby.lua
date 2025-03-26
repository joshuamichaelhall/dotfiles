-- Ruby Development Configuration for Neovim
-- Author: Joshua Michael Hall
-- GitHub: joshuamichaelhall
-- 
-- This configuration sets up Neovim for Ruby development with:
-- - LSP support via Solargraph
-- - Code formatting via Rubocop
-- - Testing via RSpec
-- - Rails-specific functionality
-- - Debugging via Ruby Debug IDE
-- - Bundler integration

-- Load required modules
local lspconfig = require('lspconfig')
local null_ls = require('null-ls')

-- Configure Solargraph for Ruby language server
lspconfig.solargraph.setup {
  settings = {
    solargraph = {
      diagnostics = true,
      completion = true,
      hover = true,
      formatting = true,
      symbols = true,
      definitions = true,
      references = true,
      intellisense = true,
      autoformat = true,
      useBundler = false, -- Set to true if solargraph is in your Gemfile
    }
  },
  flags = {
    debounce_text_changes = 150,
  },
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
}

-- Setup Steep for Ruby type checking (optional)
pcall(function()
  lspconfig.steep.setup {
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
  }
end)

-- Setup null-ls for Rubocop integration
null_ls.setup({
  sources = {
    null_ls.builtins.formatting.rubocop.with({
      command = "rubocop",
      args = { "--auto-correct", "--stdin", "$FILENAME", "--format", "json" },
      to_stdin = true,
    }),
    null_ls.builtins.diagnostics.rubocop,
  },
})

-- Detect if we're in a Rails project
local function is_rails()
  -- Check for config/routes.rb or config/application.rb
  local rails_files = { "config/routes.rb", "config/application.rb" }
  for _, file in ipairs(rails_files) do
    if vim.fn.filereadable(file) == 1 then
      return true
    end
  end
  return false
end

-- Setup debugging for Ruby
local dap = require('dap')
dap.adapters.ruby = {
  type = 'executable',
  command = 'bundle',
  args = {'exec', 'rdbg', '-n', '--open', '--port', '${port}'},
}

dap.configurations.ruby = {
  {
    type = 'ruby',
    request = 'launch',
    name = 'Rails server',
    program = 'bundle',
    programArgs = {'exec', 'rails', 's'},
    useBundler = true,
  },
  {
    type = 'ruby',
    request = 'launch',
    name = 'RSpec current file',
    program = 'bundle',
    programArgs = {'exec', 'rspec', '${file}'},
    useBundler = true,
  },
}

-- Ruby-specific keymaps for different contexts
vim.api.nvim_create_autocmd("FileType", {
  pattern = "ruby",
  callback = function()
    local opts = { buffer = true, silent = true }
    
    -- Basic Ruby commands
    vim.keymap.set("n", "<leader>rr", ":w<CR>:sp<CR>:term ruby %<CR>", 
      { buffer = true, desc = "Run Ruby file" })
    
    vim.keymap.set("n", "<leader>rf", function()
      vim.lsp.buf.format()
    end, { buffer = true, desc = "Format Ruby file" })
    
    -- Testing with RSpec
    vim.keymap.set("n", "<leader>rt", ":w<CR>:sp<CR>:term bundle exec rspec<CR>", 
      { buffer = true, desc = "Run all RSpec tests" })
    
    vim.keymap.set("n", "<leader>rT", ":w<CR>:sp<CR>:term bundle exec rspec %<CR>", 
      { buffer = true, desc = "Run RSpec on current file" })
    
    vim.keymap.set("n", "<leader>rl", function()
      -- Run RSpec on the line under cursor
      local line = vim.fn.line(".")
      vim.cmd(string.format(":w<CR>:sp<CR>:term bundle exec rspec %%:%d", line))
    end, { buffer = true, desc = "Run RSpec on current line" })
    
    -- Bundle commands
    vim.keymap.set("n", "<leader>rb", ":!bundle install<CR>", 
      { buffer = true, desc = "Bundle install" })
    
    vim.keymap.set("n", "<leader>ru", ":!bundle update<CR>", 
      { buffer = true, desc = "Bundle update" })
    
    -- Debugging
    vim.keymap.set("n", "<leader>rd", function()
      require('dap').continue()
    end, { buffer = true, desc = "Debug Ruby file" })
    
    -- Rails-specific commands (only in Rails projects)
    if is_rails() then
      -- Rails server
      vim.keymap.set("n", "<leader>Rs", ":sp<CR>:term bundle exec rails server<CR>", 
        { buffer = true, desc = "Start Rails server" })
      
      -- Rails console
      vim.keymap.set("n", "<leader>Rc", ":sp<CR>:term bundle exec rails console<CR>", 
        { buffer = true, desc = "Start Rails console" })
      
      -- Database commands
      vim.keymap.set("n", "<leader>Rd", ":sp<CR>:term bundle exec rails db:migrate<CR>", 
        { buffer = true, desc = "Run migrations" })
      
      vim.keymap.set("n", "<leader>RD", ":sp<CR>:term bundle exec rails db:rollback<CR>", 
        { buffer = true, desc = "Rollback migration" })
      
      -- Routes
      vim.keymap.set("n", "<leader>Rr", ":sp<CR>:term bundle exec rails routes<CR>", 
        { buffer = true, desc = "Display Rails routes" })
      
      -- Generate
      vim.keymap.set("n", "<leader>Rg", function()
        vim.ui.input({ prompt = "Generate: " }, function(input)
          if input then
            vim.cmd(string.format(":sp<CR>:term bundle exec rails generate %s", input))
          end
        end)
      end, { buffer = true, desc = "Rails generate" })
      
      -- Destroy
      vim.keymap.set("n", "<leader>RD", function()
        vim.ui.input({ prompt = "Destroy: " }, function(input)
          if input then
            vim.cmd(string.format(":sp<CR>:term bundle exec rails destroy %s", input))
          end
        end)
      end, { buffer = true, desc = "Rails destroy" })
    end
  end,
})

-- Setup file templates
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.rb",
  callback = function()
    -- Check if we're in a possible Rails controller
    local filename = vim.fn.expand("%:t")
    if filename:match("_controller%.rb$") then
      local template = {
        "# frozen_string_literal: true",
        "",
        "class " .. filename:gsub("_controller%.rb$", ""):gsub("^%l", string.upper):gsub("_%l", string.upper):gsub("_", "") .. "Controller < ApplicationController",
        "  before_action :set_" .. filename:gsub("_controller%.rb$", ""):gsub("s$", ""),
        "",
        "  # GET /" .. filename:gsub("_controller%.rb$", ""),
        "  def index",
        "    @" .. filename:gsub("_controller%.rb$", ""),
        "  end",
        "",
        "  # GET /" .. filename:gsub("_controller%.rb$", "") .. "/1",
        "  def show",
        "  end",
        "",
        "  # GET /" .. filename:gsub("_controller%.rb$", "") .. "/new",
        "  def new",
        "    @" .. filename:gsub("_controller%.rb$", ""):gsub("s$", "") .. " = " .. filename:gsub("_controller%.rb$", ""):gsub("s$", ""):gsub("^%l", string.upper):gsub("_%l", string.upper):gsub("_", "") .. ".new",
        "  end",
        "",
        "  # POST /" .. filename:gsub("_controller%.rb$", ""),
        "  def create",
        "    @" .. filename:gsub("_controller%.rb$", ""):gsub("s$", "") .. " = " .. filename:gsub("_controller%.rb$", ""):gsub("s$", ""):gsub("^%l", string.upper):gsub("_%l", string.upper):gsub("_", "") .. ".new(" .. filename:gsub("_controller%.rb$", ""):gsub("s$", "") .. "_params)",
        "",
        "    if @" .. filename:gsub("_controller%.rb$", ""):gsub("s$", "") .. ".save",
        "      redirect_to @" .. filename:gsub("_controller%.rb$", ""):gsub("s$", "") .. ", notice: '" .. filename:gsub("_controller%.rb$", ""):gsub("s$", ""):gsub("^%l", string.upper):gsub("_%l", string.upper):gsub("_", "") .. " was successfully created.'",
        "    else",
        "      render :new",
        "    end",
        "  end",
        "",
        "  private",
        "",
        "  def set_" .. filename:gsub("_controller%.rb$", ""):gsub("s$", ""),
        "    @" .. filename:gsub("_controller%.rb$", ""):gsub("s$", "") .. " = " .. filename:gsub("_controller%.rb$", ""):gsub("s$", ""):gsub("^%l", string.upper):gsub("_%l", string.upper):gsub("_", "") .. ".find(params[:id])",
        "  end",
        "",
        "  def " .. filename:gsub("_controller%.rb$", ""):gsub("s$", "") .. "_params",
        "    params.require(:" .. filename:gsub("_controller%.rb$", ""):gsub("s$", "") .. ").permit()",
        "  end",
        "end",
        "",
      }
      vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
    -- Check if we're in a possible Rails model
    elseif filename:match("%.rb$") and not filename:match("_spec%.rb$") and is_rails() then
      local class_name = filename:gsub("%.rb$", ""):gsub("^%l", string.upper):gsub("_%l", string.upper):gsub("_", "")
      local template = {
        "# frozen_string_literal: true",
        "",
        "class " .. class_name .. " < ApplicationRecord",
        "  # Include default validations, associations, scopes, and callbacks",
        "  validates :name, presence: true",
        "  ",
        "  # Add your model methods here",
        "end",
        "",
      }
      vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
    -- Default Ruby template
    else
      local template = {
        "# frozen_string_literal: true",
        "",
        "# Description: ",
        "",
        "",
        "",
      }
      vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
      vim.cmd("normal! 3G$")
    end
  end
})

-- Recommended plugins for Ruby development (add these to your Lazy setup)
-- Comment out any you don't want to use
local ruby_plugins = {
  -- 'tpope/vim-rails',
  -- 'tpope/vim-bundler',
  -- 'thoughtbot/vim-rspec',
  -- 'vim-ruby/vim-ruby',
}

-- Display Rails environment in statusline
local function rails_env()
  if is_rails() then
    local env = vim.fn.system("RAILS_ENV")
    if env == "" then
      env = "development"
    end
    return "[Rails:" .. env:gsub("%s+", "") .. "]"
  end
  return ""
end

-- Ensure this is available to lualine or other statusline plugins
_G.rails_env = rails_env