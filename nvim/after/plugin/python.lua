-- Python Development Configuration for Neovim
-- Author: Joshua Michael Hall
-- GitHub: joshuamichaelhall
-- 
-- This configuration sets up Neovim for Python development with:
-- - LSP support via Pyright
-- - Code formatting via Black
-- - Import sorting via isort
-- - Testing via pytest
-- - Virtual environment support
-- - Debugging via DAP

-- Enable Python LSP (Pyright)
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        -- Enable more detailed analysis
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
        },
      },
    },
  },
  -- Configure capabilities with nvim-cmp
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  -- Enable automatic Python virtual environment detection
  on_new_config = function(new_config, new_root_dir)
    -- Try to find and use virtual environment
    local util = require('lspconfig.util')
    local path = util.path
    
    -- Check for virtualenv in project directory
    local venv_path = util.find_git_ancestor(new_root_dir)
    if venv_path then
      -- Look for venv in standard locations
      for _, pattern in ipairs({ "*venv*/bin/python", ".venv/bin/python", "venv/bin/python" }) do
        local match = vim.fn.glob(path.join(venv_path, pattern))
        if match ~= "" then
          new_config.settings.python.pythonPath = match
          break
        end
      end
    end
  end,
}

-- Configure Python formatting tools
local null_ls = require('null-ls')
null_ls.setup({
  sources = {
    -- Black for code formatting
    null_ls.builtins.formatting.black.with({
      extra_args = { "--line-length=88" }
    }),
    -- isort for import sorting
    null_ls.builtins.formatting.isort.with({
      extra_args = { "--profile", "black" }
    }),
    -- Flake8 for linting
    null_ls.builtins.diagnostics.flake8.with({
      extra_args = { "--max-line-length=88", "--extend-ignore=E203" }
    }),
  },
})

-- Setup nvim-dap for Python debugging
local dap = require('dap')
dap.adapters.python = {
  type = 'executable',
  command = 'python',
  args = { '-m', 'debugpy.adapter' },
}

dap.configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = 'Launch file',
    program = "${file}",
    pythonPath = function()
      -- Try to automatically detect virtualenv
      local venv = os.getenv('VIRTUAL_ENV')
      if venv then
        return venv .. '/bin/python'
      end
      return 'python'
    end,
  },
}

-- Python-specific keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    local opts = { buffer = true, silent = true }
    
    -- Format and organize imports
    vim.keymap.set("n", "<leader>pf", function()
      vim.cmd("silent !black %")
      vim.cmd("silent !isort %")
      vim.cmd("e")  -- Reload the file
    end, { buffer = true, desc = "Format Python file" })
    
    -- Run current file
    vim.keymap.set("n", "<leader>pr", ":w<CR>:sp<CR>:term python %<CR>", 
      { buffer = true, desc = "Run Python file" })
    
    -- Run tests
    vim.keymap.set("n", "<leader>pt", ":w<CR>:sp<CR>:term pytest<CR>", 
      { buffer = true, desc = "Run pytest" })
    
    -- Run specific test
    vim.keymap.set("n", "<leader>pT", ":w<CR>:sp<CR>:term pytest %<CR>", 
      { buffer = true, desc = "Run pytest on current file" })
    
    -- Debug current file
    vim.keymap.set("n", "<leader>pd", function()
      require('dap').continue()
    end, { buffer = true, desc = "Debug Python file" })
    
    -- Create/activate virtual environment
    vim.keymap.set("n", "<leader>pv", function()
      -- Check if virtualenv exists
      if vim.fn.isdirectory("venv") == 1 then
        vim.cmd("!source venv/bin/activate")
        print("Activated virtual environment")
      else
        vim.cmd("!python -m venv venv && source venv/bin/activate")
        print("Created and activated virtual environment")
      end
    end, { buffer = true, desc = "Create/activate venv" })
    
    -- Install requirements
    vim.keymap.set("n", "<leader>pi", ":!pip install -r requirements.txt<CR>", 
      { buffer = true, desc = "Install requirements" })
    
    -- Generate requirements.txt
    vim.keymap.set("n", "<leader>pg", ":!pip freeze > requirements.txt<CR>", 
      { buffer = true, desc = "Generate requirements.txt" })
    
    -- Toggle docstring generation (using docstring-generator.nvim if available)
    if pcall(require, "docstring-generator") then
      vim.keymap.set("n", "<leader>ps", ":GenerateDoctring<CR>", 
        { buffer = true, desc = "Generate docstring" })
    end
  end,
})

-- Recommended plugins for Python development (add these to your Lazy setup)
-- Comment out any you don't want to use
local python_plugins = {
  -- 'mfussenegger/nvim-dap-python',
  -- 'HallerPatrick/py_lsp.nvim',
  -- 'nvim-treesitter/nvim-treesitter',
  -- 'kkoomen/vim-doge',
}

-- Optional: setup Python templates
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.py",
  callback = function()
    local template = {
      "#!/usr/bin/env python3",
      "# -*- coding: utf-8 -*-",
      "\"\"\"",
      "$1",
      "\"\"\"",
      "",
      "",
      "def main():",
      "    pass",
      "",
      "",
      "if __name__ == \"__main__\":",
      "    main()",
      "",
    }
    vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
    vim.cmd("normal! 4G$")
  end
})

-- Display virtual environment in statusline
local function python_venv()
  local venv = os.getenv('VIRTUAL_ENV')
  if venv then
    local venv_name = venv:match("([^/]+)$")
    return "(" .. venv_name .. ")"
  end
  return ""
end

-- Ensure this is available to lualine or other statusline plugins
_G.python_venv = python_venv