return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({
        options = { transparent = true },
      })
    end,
  },
  -- {
  --   "catppuccin/nvim",
  -- },
  -- {
  --   "rebelot/kanagawa.nvim",
  --   opts = {
  --     theme = "dragon",
  --   },
  -- },
  -- {
  --   "ellisonleao/gruvbox.nvim",
  --   priority = 1000,
  --   config = true,
  --   opts = {
  --     contrast = "", -- can be "hard", "soft" or empty string
  --   },
  -- },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark_default",
      -- colorscheme = "catppuccin-mocha",
      -- colorscheme = "kanagawa-dragon",
      -- colorscheme = "gruvbox",
      -- background = "light",
    },
  },
}
