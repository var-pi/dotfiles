vim.lsp.enable'ty'
vim.lsp.enable'lua_ls'
vim.lsp.enable'texlab'
vim.lsp.enable'nixd'
vim.lsp.enable'julials'

vim.lsp.config('ty', {
    settings = {
        ty = {
            experimental = {
                rename = true
            }
        }
    }
})

vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            diagnostics = {
                globals = { "vim" }
            }
        }
    }
})
