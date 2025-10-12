return {
  "telescope.nvim",
  dependencies = {
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
      config = function(_, _)
        require("lazyvim.util").on_load("telescope.nvim", function()
          require("telescope").load_extension("live_grep_args")
        end)
      end,
      keys = {
        { "<leader>/", ":Telescope live_grep_args<CR>", desc = "Live Grep" },
      },
    },
  },
}
