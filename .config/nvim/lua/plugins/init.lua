-- TODO Auto close paren

-- TODO
-- Add "hrsh7th/cmp-buffer",
-- Add "hrsh7th/cmp-path",
-- Cmp for latex
-- Ollama.Copilot
-- Dependencies into their places
-- Sort imports logically
-- Auto indentation
-- Replace the nvim-cmp plugin with blink.cmp
-- Auto doc
-- Do not show underscore properties in cmp
-- Mason instead of pulling language servers by hand?
-- Forward search for latex?

vim.pack.add({
    -- Suggestions in a popup menu 
    { src = "https://github.com/hrsh7th/nvim-cmp" },
    -- Pass suggstion information from a ls to cmp.
    { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },

    -- A strip with information about the editing session.
    { src = "https://github.com/nvim-lualine/lualine.nvim" },

    -- A theme.
    { src = "https://github.com/catppuccin/nvim" },

    -- Lua utility library.
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    -- Management and integration of ollama workflows.
    { src = "https://github.com/nomnivore/ollama.nvim" },
})

require('plugins.cmp')()
require('plugins.ollama')()
require('plugins.lualine')()
