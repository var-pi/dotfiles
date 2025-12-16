require'blink.cmp'.setup{
    keymap = { preset = 'default' },
    sources = {
        default = { 'lsp', 'path' },
    },
    fuzzy = {
        implementation = "rust",
        prebuilt_binaries = {
            force_version = 'v1.8.0',
        }
    },
    completion = {
        accept = {
            auto_brackets = {
                enabled = true,
                blocked_filetypes = { 'lua' },
                override_brackets_for_filetypes = {},
            }
        }
    },
}
