require('options')
require('keymaps')

vim.pack.add({
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/folke/which-key.nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/echasnovski/mini.pairs" },
	{ src = "https://github.com/echasnovski/mini.ai" },
	{ src = "https://github.com/echasnovski/mini.icons" },
	{ src = "https://github.com/echasnovski/mini.move" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/rmagatti/auto-session" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/williamboman/mason-lspconfig.nvim" },
	{ src = "https://github.com/ibhagwan/smartyank.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/tpope/vim-fugitive" },
	{ src = "https://github.com/folke/flash.nvim" },
})

local parsers = {
	'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown',
	'markdown_inline', 'query', 'vim', 'vimdoc', 'regex', 'go'
}
require('nvim-treesitter').install(parsers)
require "which-key".setup({ preset = "helix", delay = 0, })
require "mason".setup()
require("auto-session").setup()
require('smartyank').setup({ highlight = { enabled = false } })

require('oil-config')
require('flash-config')
require('colorscheme')
require('lsp')
require('mini')
require('statusline')
require('formatting')
