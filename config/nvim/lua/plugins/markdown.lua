-- ~/.config/nvim/lua/plugins/markdown.lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
    config = function()
      require("render-markdown").setup({
        -- v8.x 只保留这些可配置项，其余全部删掉
        heading = {
          enabled = true,
          sign = true,
          icons = { "H1", "H2", "H3", "H4", "H5", "H6" },
          backgrounds = { "none" },
        },

        code = {
          enabled = true,
          style = "full",
          language = true,
        },

        bullet = {
          enabled = true,
          icons = { "●", "○", "◆", "◇", "►", "▸" },
        },

        quote = {
          enabled = true,
          repeat_linebreak = true,
        },

        checkbox = {
          enabled = true,
          unchecked = { icon = "☐ " },
          checked = { icon = "☑ " },
        },

        dash = { enabled = true },

        debounce = 200, -- 注意：直接写 number，不是 table

        -- latex 在 v8 里如果支持也是简单开关
        -- latex = { enabled = false },  -- 如果报错就删掉这行
      })
    end,
  },

  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdown", "markdown_inline" })
    end,
  },

  -- 快捷键
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>m", group = "Markdown" },
        { "<leader>mt", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle render" },
        { "<leader>ms", "<cmd>RenderMarkdown start<cr>", desc = "Start render" },
        { "<leader>mq", "<cmd>RenderMarkdown stop<cr>", desc = "Stop render" },
      },
    },
  },
}
