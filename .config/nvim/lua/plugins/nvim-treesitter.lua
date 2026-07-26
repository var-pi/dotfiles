-- The `main` branch is a full rewrite: the plugin now only installs parsers
-- and queries. The features themselves (highlighting, folds, indentation) are
-- Neovim built-ins that have to be enabled per buffer.

local languages = { 'python', 'lua', 'latex', 'nix', 'json', 'julia' }

-- Asynchronous, and a no-op for parsers that are already installed.
require'nvim-treesitter'.install(languages)

-- Parsers are pinned to the plugin revision, so refresh them along with it.
vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('nvim-treesitter-pack', { clear = true }),
    callback = function(event)
        local kind = event.data.kind
        if event.data.spec.name == 'nvim-treesitter'
            and (kind == 'install' or kind == 'update') then
            require'nvim-treesitter'.update()
        end
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('nvim-treesitter-enable', { clear = true }),
    callback = function(event)
        local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
        if not lang or not vim.treesitter.language.add(lang) then
            return
        end

        -- Syntax highlighting, provided by Neovim.
        vim.treesitter.start(event.buf, lang)

        -- Folds, provided by Neovim.
        vim.wo[0][0].foldmethod = 'expr'
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'

        -- Indentation, provided by nvim-treesitter (experimental).
        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

        -- Incremental selection is gone from the plugin; Neovim ships its own
        -- as `an`/`in` in visual mode, see |treesitter-incremental-selection|.
        local opts = { buffer = event.buf, remap = true }
        vim.keymap.set('n', '<CR>', 'van', vim.tbl_extend('force', opts,
            { desc = 'Select node under cursor' }))
        vim.keymap.set('x', '<CR>', 'an', vim.tbl_extend('force', opts,
            { desc = 'Select parent node' }))
        vim.keymap.set('x', '<BS>', 'in', vim.tbl_extend('force', opts,
            { desc = 'Select child node' }))
    end,
})
