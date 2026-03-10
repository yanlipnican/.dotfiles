return {
  -- Inline ghost-text completions via your own API keys
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("minuet").setup({
        provider = "claude",
        provider_options = {
          claude = {
            api_key = "ANTHROPIC_API_KEY", -- reads from $ANTHROPIC_API_KEY env var
            model = "claude-haiku-4-5-20251001", -- fast + cheap for completions
          },
        },
        virtualtext = {
          auto_trigger_ft = { "*" },
          keymap = {
            accept = "<Tab>",
            accept_line = "<A-a>",
            accept_n_lines = "<A-z>",
            prev = "<A-[>",
            next = "<A-]>",
            dismiss = "<S-Tab>",
          },
        },
      })
    end,
  },

  -- Cursor-like AI sidebar + inline editing
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    build = "make",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      provider = "claude",
      providers = {
        claude = {
          endpoint = "https://api.anthropic.com",
          model = "claude-sonnet-4-6",
              extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
      },
    },
  },

  -- Integrate minuet with blink.cmp
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = vim.list_extend(opts.sources.default or {}, { "minuet" })
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        minuet = {
          name = "minuet",
          module = "minuet.blink",
          score_offset = 8,
        },
      })
      return opts
    end,
  },
}
