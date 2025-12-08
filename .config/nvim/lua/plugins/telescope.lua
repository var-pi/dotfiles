require'telescope'.setup{
    defaults = {
        mappings = {
            i = {
                ['<C-h>'] = 'which_key',
            }
        }
    },
    pickers = {

    },
    extensions = {

    }
}

local builtin = require("telescope.builtin")
vim.keymap.set('n', '<leader>ff', builtin.find_files)
