return {
  "telescope.nvim",
  keys = {
    {
      "<leader>fP",
      function()
        require("telescope.builtin").find_files({
          prompt_title = "Claude Plans",
          cwd = ".claude/plans",
          hidden = true,
          no_ignore = true,
        })
      end,
      desc = "Find Claude Plans",
    },
  },
  opts = {
    defaults = {
      file_ignore_patterns = {},
    },
    pickers = {
      find_files = {
        hidden = true,
      },
    },
  },
  dependencies = {
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
      config = function(_, _)
        require("lazyvim.util").on_load("telescope.nvim", function()
          require("telescope").load_extension("live_grep_args")
        end)
      end,
      attach_mappings = function()
        vim.keymap.set("i", "<C-v>", '<C-r>+', { buffer = true })
      end,
      keys = {
        { "<leader>/", ":Telescope live_grep_args<CR>", desc = "Live Grep" },
      },
    },
  },
}
