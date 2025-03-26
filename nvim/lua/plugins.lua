-- This file can be loaded by calling `lua require('plugins')` from your init.lua

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  
  -- Color scheme
  use 'morhetz/gruvbox'
  
  -- File explorer
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- optional, for file icons
    }
  }
  
  -- Fuzzy finder
  use {
    'nvim-telescope/telescope.nvim',
    requires = { 'nvim-lua/plenary.nvim' }
  }
  
  -- LSP Configuration
  use 'neovim/nvim-lspconfig'
  
  -- Autocompletion
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  
  -- Snippets
  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'
  
  -- Git integration
  use 'tpope/vim-fugitive'
  use 'lewis6991/gitsigns.nvim'
  
  -- Status line
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true }
  }
  
  -- Treesitter for better syntax highlighting
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      require('nvim-treesitter.install').update({ with_sync = true })
    end,
  }
  
  -- Terminal integration
  use 'akinsho/toggleterm.nvim'
  
  -- Required for DAP UI
  use 'nvim-neotest/nvim-nio'  -- Added this line for nvim-dap-ui dependency
  
  -- Debugging with DAP (Debug Adapter Protocol)
  use 'mfussenegger/nvim-dap' -- Core DAP functionality
  use 'rcarriga/nvim-dap-ui' -- UI for DAP
  use 'theHamsta/nvim-dap-virtual-text' -- Virtual text for DAP
  use 'mfussenegger/nvim-dap-python' -- Python debugger
  
  -- Code formatting and linting
  use 'jose-elias-alvarez/null-ls.nvim' -- Required for linting and formatting
  
  -- Language specific plugins
  -- Ruby
  use 'vim-ruby/vim-ruby'
  use 'tpope/vim-rails'
  
  -- Python
  use 'davidhalter/jedi-vim'
  
  -- JavaScript
  use 'pangloss/vim-javascript'
  use 'maxmellon/vim-jsx-pretty'
  
  -- TypeScript - using ts_ls instead of tsserver
  use 'leafgarland/typescript-vim'
  
  -- Database integration
  use 'tpope/vim-dadbod'
  use 'kristijanhusak/vim-dadbod-ui'
  
  -- Markdown preview
  use {
    'iamcco/markdown-preview.nvim',
    run = function() vim.fn['mkdp#util#install']() end,
    ft = { 'markdown' }
  }
  
  -- Additional plugins for terminal-centric workflow
  use 'christoomey/vim-tmux-navigator'  -- Seamless navigation between tmux panes and vim splits
  use 'preservim/tagbar'  -- Code structure viewer
  use 'junegunn/fzf'  -- Command-line fuzzy finder
  use 'junegunn/fzf.vim'  -- Vim plugin for fzf
  
  -- Additional helpful plugins
  use 'jiangmiao/auto-pairs'  -- Auto-close brackets, quotes, etc.
  use 'tpope/vim-commentary'  -- Easy commenting
  use 'tpope/vim-surround'    -- Surround text with quotes, brackets, etc.
  use 'airblade/vim-rooter'   -- Change working directory to project root
  
  -- Mason for LSP, DAP, linter, and formatter management
  use {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
  }

  -- Vimwiki
  use 'vimwiki/vimwiki'
end)
