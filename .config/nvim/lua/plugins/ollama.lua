return function()
    local ollama = require("ollama")

    ollama.setup({
        model = "deepseek-coder-v2:16b-lite-instruct-q4_K_M",
        serve = {
            on_start = false,
            on_exit = false,
        },
    })

    vim.keymap.set({"n", "v"}, "<leader>oo", ollama.prompt)
end
