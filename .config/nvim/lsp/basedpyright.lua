return {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
    on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true }
    end,
}
