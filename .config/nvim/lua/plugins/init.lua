vim.pack.add{
    -- Config files for language servers.
    { src = 'https://github.com/neovim/nvim-lspconfig' },

    -- Preview markdown.
    { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },

    -- LSP support ++
    { src = 'https://github.com/saghen/blink.cmp' },

    -- A strip with information about the editing session.
    { src = 'https://github.com/nvim-lualine/lualine.nvim' },

    -- A theme.
    { src = 'https://github.com/catppuccin/nvim' },

    -- Lua utility library.
    { src = 'https://github.com/nvim-lua/plenary.nvim' },

    -- Features basedon code tree representation.
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },

    -- Automatically add a pairing bracket, quote etc.
    { src = 'https://github.com/windwp/nvim-autopairs' },

    -- Fuzzy search.
    { src = 'https://github.com/nvim-telescope/telescope.nvim' },
}

--require'plugins.lspconfig'
require'plugins.blink'
require'plugins.lualine'
require'plugins.nvim-treesitter'
require'plugins.nvim-autopairs'
require'plugins.telescope'
