-- TODO Auto close paren

-- TODO
-- Add "hrsh7th/cmp-buffer",
-- Add "hrsh7th/cmp-path",
-- Cmp for lua and latex
-- Ollama.Copilot
-- Dependencies into their places
-- Sort imports logically
-- Auto indentation

vim.pack.add({
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/hrsh7th/nvim-cmp" },
    { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
    { src = "https://github.com/rafamadriz/friendly-snippets" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/saadparwaiz1/cmp_luasnip" },
    { src = "https://github.com/nomnivore/ollama.nvim" },
    { src = "https://github.com/nvim-lua/plenary.nvim" }, -- For ollama
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/catppuccin/nvim" },
})

require('plugins.luasnip')()
require('plugins.cmp')()
require('plugins.ollama')()
require('plugins.lualine')()
