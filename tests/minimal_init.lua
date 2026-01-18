-- Minimal init for running tests
-- Add the plugin to runtime path
vim.opt.rtp:append('.')
vim.opt.rtp:append('~/.local/share/nvim/lazy/plenary.nvim')
vim.opt.rtp:append('~/.local/share/nvim/lazy/telescope.nvim')

-- For testing
vim.cmd [[runtime plugin/plenary.vim]]
