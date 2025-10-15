vim.o.guifont = "JetBrainsMono Nerd Font:h14"
vim.g.neovide_theme = 'dark'

-- Allow clipboard copy paste in neovim
vim.keymap.set(
    {'n', 'v', 's', 'x', 'o', 'i', 'l', 'c', 't'},
    '<D-v>',
    function() vim.api.nvim_paste(vim.fn.getreg('+'), true, -1) end,
    { noremap = true, silent = true }
)
