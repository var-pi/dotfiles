require'codecompanion.init'.setup{
    strategies = {
        chat = {
            adapter = "ollama",
            model = "phi3.5:3.8b-mini-instruct-q4_K_M",
        },
        inline = {
            adapter = "ollama",
            --model = "phi3.5:3.8b-mini-instruct-q4_K_M",
            mode = 'deepseek-coder-v2:16b-lite-instruct-q5_K_M'
        }
    },
}

vim.keymap.set({ "n", "v" }, "<Leader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.cmd([[cab cc CodeCompanion]])


