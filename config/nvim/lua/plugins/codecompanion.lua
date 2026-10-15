return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = function(_, opts)
      opts.interactions = {
        chat = { adapter = { name = "deepseek", model = "deepseek-flash" } },
        inline = { adapter = { name = "deepseek", model = "deepseek-flash" } },
        cmd = { adapter = "deepseek" },
      }

      -- 想用 OpenAI 就改成：
      -- opts.interactions = {
      --   chat = { adapter = { name = "openai", model = "gpt-4.1" } },
      --   inline = { adapter = "openai" },
      -- }

      opts.opts = opts.opts or {}
    end,
  },
}
