require("lualine").setup({
    options = {
        theme = "palenight",
        component_separators = '',
        section_separators = {left = '', right = ''},
    },
    sections = {
        lualine_x = {
            {
                function()
                    local ollama_status = require("ollama").status()

                    local icons = {
                        "󱙺",
                        "󰚩",
                    }

                    if ollama_status == "IDLE" then
                        return icons[1]
                    elseif ollama_status == "WORKING" then
                        return icons[(os.date("%S") % #icons) + 1]
                    end

                    return ""
                end,
                cond = function()
                    return package.loaded["ollama"] and require("ollama").status() ~= nil
                end,
                padding = { left = 1, right = 1 }
            },
        },
    },
})
