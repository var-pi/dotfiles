require'blink.cmp'.setup{
    version = '1.8',
    opts = {
        keymap = { preset = 'default' },
        sources = {
            default = { 'lsp', 'path' },
        },
    },
    fuzzy = {
        implementation = "lua",
    },
    completion = {
        accept = {
            auto_brackets = {
                enabled = true,
                blocked_filetypes = { 'prefer_rust_with_warning' },
            }
        }
    }
}
