-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Set light background for Gruvbox
-- vim.opt.background = "light"

return {
  {
    "ahmedkhalf/project.nvim",
    opts = {
      detection_methods = { "pattern" },
      patterns = { ".git" },
    },
  },
}
