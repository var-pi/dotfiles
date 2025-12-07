return function()
    require("ollama").setup({
        model = "deepseek-coder-v2:16b-lite-instruct-q4_K_M",
        serve = {
            on_start = false,
            on_exit = false,
        },
    })
end
