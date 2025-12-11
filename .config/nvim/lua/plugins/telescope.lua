require'telescope.init'.setup{
    defaults = {
        path_display = {
            "filename_first",
        },
        borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
        mappings = {
            i = {
                ['<C-h>'] = 'which_key',
            }
        },
        layout_strategy='horizontal',
        layout_config = {
            horizontal = {
                prompt_position = "top",
                width = { padding = 0 },
                height = { padding = 0 },
                preview_width = 0.5,
            },
        },
        sorting_strategy = "ascending",
    },
    pickers = {
        find_files = {
            prompt_title = false,
            results_title = false,
            preview_title = false,
        },
        live_grep = {
            prompt_title = false,
            results_title = false,
            preview_title = false,
        },
        buffers = {
            prompt_title = false,
            results_title = false,
            preview_title = false,
        },
        grep_string = {
            prompt_title = false,
            results_title = false,
            preview_title = false,
        },
        git_files = {
            prompt_title = false,
            results_title = false,
            preview_title = false,
        },
    },
    extensions = {

    }
}

local builtin = require("telescope.builtin")
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files'})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
