require('oil').setup({
            default_file_explorer = not (#vim.fn.argv() == 1 and vim.fn.argv()[1] == "."),
            keymaps = {
                ["<bs>"] = { "actions.parent", mode = "n" },
                ["<esc>"] = { "actions.parent", mode = "n" },
                ["q"] = { "actions.close", mode = "n" },
                ["<leader>e"] = { "actions.close", mode = "n" },
                ["<C-e>"] = { "actions.close", mode = "n" },
            },
            view_options = {
                show_hidden = true,
                is_always_hidden = function(name, _)
                    return name == '..'
                end,
            },
            win_options = {
                winbar = "%#@comment#%{fnamemodify(v:lua.require('oil').get_current_dir(), ':~:.')}",
            }
        }
)

vim.keymap.set('n', '<leader>e', ':Oil<CR>', { desc = 'File Explorer' })
