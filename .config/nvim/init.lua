-- Terminal Development Environment Neovim Configuration

-- Initialize Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.expand('~/.vim/undodir')
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
vim.g.mapleader = " " -- Space as leader key

-- Key mappings
-- Better window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Basic utilities
vim.keymap.set('n', '<leader>w', ':w<CR>') -- Save
vim.keymap.set('n', '<leader>q', ':q<CR>') -- Quit

-- Load plugins
require("lazy").setup("plugins")

-- LSP Server Naming Guide
-- When configuring Mason LSP, use these server names:
-- Ruby: rubylsp (not ruby_lsp)
-- TypeScript: tsserver (not typescript-language-server)
-- Check server names with :Mason and https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md

-- LSP Server Naming Guide
-- When configuring Mason LSP, use these server names:
-- Ruby: rubylsp (not ruby_lsp)
-- TypeScript: tsserver (not typescript-language-server)
-- Check server names with :Mason and https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
