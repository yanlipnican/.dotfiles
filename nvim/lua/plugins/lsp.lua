return {
  -- {
  --   "nvim-treesitter/nvim-treesitter",
  --   opts = { ensure_installed = { "vue", "css" } },
  -- },
  -- {
  --   "williamboman/mason.nvim",
  --   opts = {
  --     ensure_installed = {
  --       "gopls",
  --       "typescript-language-server",
  --       "vue-language-server",
  --     },
  --   },
  -- },
  -- {
  --   "nvim-lspconfig",
  --   keys = {},
  --   opts = function(_, opts)
  --       table.insert(opts.servers.vtsls.filetypes, "vue")
  --       LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
  --         {
  --           name = "@vue/typescript-plugin",
  --           location = LazyVim.get_pkg_path("vue-language-server", "/node_modules/@vue/language-server"),
  --           languages = { "vue" },
  --           configNamespace = "typescript",
  --           enableForWorkspaceTypeScriptVersions = true,
  --         },
  --       })
  --     end,
  -- },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "marilari88/neotest-vitest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
      },
    },
  }
}
