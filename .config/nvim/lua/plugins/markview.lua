require'markview'.setup{
    preview = {
        filetypes = { "markdown", "codecompanion" },
        ignore_buftypes = {},
    },
}

-- Remove when nixpk
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'codecompanion',
    command = 'Markview attach',
})
