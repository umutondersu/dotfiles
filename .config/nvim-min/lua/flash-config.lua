require('flash').setup({
	modes = {
		search = { enabled = true },
		char = { jump_labels = true },
	},
})

local map = vim.keymap.set

map({ 'n', 'o', 'x' }, 's', function() require('flash').jump() end, { desc = 'Flash Jump' })
map({ 'n', 'o', 'x' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash Treesitter Selection' })
map('o', 'r', function() require('flash').remote() end, { desc = 'Remote Flash' })
map({ 'o', 'x' }, 'R', function() require('flash').treesitter_search() end, { desc = 'Treesitter Search' })
map('c', '<C-s>', function() require('flash').toggle() end, { desc = 'Toggle Flash Search' })