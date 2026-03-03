return {
  "coder/claudecode.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  opts = {
    terminal = {
      provider = "none",
    },
  },
  keys = {
    { "<leader>C", nil, desc = "Claude Code" },
    { "<leader>Cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>Cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>Cs",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
    { "<leader>Ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>Cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
