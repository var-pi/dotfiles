return function()
    require("ollama").setup({
        -- Set your preferred local model
        model = "deepseek-coder:6.7b-instruct-q5_K_M",

        -- Configuration for the Ollama server itself
        serve = {
            -- Start the Ollama server when Neovim starts
            on_start = false,
            -- Stop the server when Neovim exits
            on_exit = false,
        },
    })
end
