require "mini.pick".setup()
require "mini.ai".setup()
require "mini.pairs".setup()
require "mini.icons".setup()
require "mini.move".setup(
	{
		mappings = {
			left = 'H',
			right = 'L',
			down = 'J',
			up = 'K',
			line_left = '',
			line_right = '',
			line_down = '<M-j>',
			line_up = '<M-k>',
		},
	}
)

local map = vim.keymap.set
map('n', '<leader>s', ":Pick files<CR>", { desc = "Search Files" })
map('n', '<leader>h', ":Pick help<CR>", { desc = "Search Help" })
map('n', '<leader>r', ":Pick grep_live<CR>", { desc = "Search RipGrep" })
map('n', '<leader><space>', ":Pick buffers<CR>", { desc = "Pick Buffer" })
