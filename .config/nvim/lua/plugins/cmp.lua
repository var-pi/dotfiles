local function no_underscores(entry, _)
    local label = entry:get_completion_item().label
    return not label:match('^_')
end

local cmp = require('cmp')

cmp.setup{
    mapping = cmp.mapping.preset.insert{
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm{ select = true },
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif vim.snippet.active{ direction = 1 } then
                vim.snippet.jump(1)
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif vim.snippet.active{ direction = -1 } then
                vim.snippet.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
    },
    sources = cmp.config.sources{
        { name = 'nvim_lsp', entry_filter = no_underscores }
    },
}
