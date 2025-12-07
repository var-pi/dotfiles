-- TODO
-- Auto close paren
-- Ollama.Copilot
-- Replace the nvim-cmp plugin with blink.cmp
-- Auto doc
-- Mason instead of pulling language servers by hand?
-- Forward search for latex?
-- Learn about a treesitter
-- Add options

vim.pack.add{
    -- Suggestions in a popup menu 
    { src = 'https://github.com/hrsh7th/nvim-cmp' },
    -- Pass suggstion information from a ls to cmp.
    { src = 'https://github.com/hrsh7th/cmp-nvim-lsp' },

    -- A strip with information about the editing session.
    { src = 'https://github.com/nvim-lualine/lualine.nvim' },

    -- A theme.
    { src = 'https://github.com/catppuccin/nvim' },

    -- Lua utility library.
    { src = 'https://github.com/nvim-lua/plenary.nvim' },
    -- Management and integration of ollama workflows.
    { src = 'https://github.com/nomnivore/ollama.nvim' },

    -- Features basedon code tree representation.
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },

    -- Automatically add a pairing brackets, quotes etc.
    { src = 'https://github.com/windwp/nvim-autopairs' },
}

require'plugins.cmp'
require'plugins.ollama'
require'plugins.lualine'
require'plugins.nvim-treesitter'
require'plugins.nvim-autopairs'
