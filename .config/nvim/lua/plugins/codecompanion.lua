require'codecompanion.init'.setup{
    strategies = {
        chat = {
            adapter = "ollama",
            model = "phi3.5:3.8b-mini-instruct-q4_K_M",
        },
    },
}
