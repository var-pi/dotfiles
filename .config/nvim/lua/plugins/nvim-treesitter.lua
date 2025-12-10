require'nvim-treesitter.configs'.setup{
    ensure_installed = { 'python', 'lua', 'latex', 'nix' },
    sync_install = false,
    auto_install = false,
    ignore_install = {},
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    indent = {
        enable = true
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection      = "<CR>",
            node_incremental    = "<CR>",
            node_decremental    = "<BS>",
            scope_incremental   = "<TAB>",
        },
    },
    modules = {},
}
