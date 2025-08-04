if vim.fn.has('nvim-0.12') == 0 then
	error("This configuration requires Neovim version 0.12 or higher.")
end

require('options')
require('keymaps')

vim.pack.add({
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/folke/which-key.nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/echasnovski/mini.pairs" },
	{ src = "https://github.com/echasnovski/mini.ai" },
	{ src = "https://github.com/echasnovski/mini.icons" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/rmagatti/auto-session" },
	{ src = "https://github.com/ibhagwan/smartyank.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim"},
})

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
	end,
})
vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		vim.hl.on_yank()
	end,
	group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
	pattern = '*',
})

require "which-key".setup({ preset = "helix", delay = 0, })
require "mini.pick".setup()
require "mini.ai".setup()
require "mini.pairs".setup()
require "mini.icons".setup()
require "mason".setup()
require "nvim-treesitter.configs".setup({
	highlight = { enable = true }
})
require("auto-session").setup()
require('smartyank').setup({ highlight = { enabled = false } })
require('oil').setup()

local map = vim.keymap.set
map('n', '<leader>s', ":Pick files<CR>", { desc = "Search Files" })
map('n', '<leader>h', ":Pick help<CR>", { desc = "Search Help" })
map('n', '<leader><space>', ":Pick buffers<CR>", { desc = "Pick Buffer" })
map('n', '<leader>e', ':Oil<CR>', { desc = 'File Explorer' })

local lspServers = {
	"bashls",
	"ts_ls",
	"tailwindcss",
	"dockerls",
	"jsonls",
	"emmet_language_server",
	"lua_ls",
	"basedpyright",
	"omnisharp",
	"gopls",
	"jdtls",
	"ruby_lsp",
	"fish_lsp"
}
vim.lsp.enable(lspServers)

require "tokyonight".setup({
	transparent = true,
	styles = {
		sidebars = "transparent",
		floats = "transparent",
	},
	hide_inactive_statusline = true,
	on_highlights = function(hl, c)
		local line_number_color = "#898da0"
		local LineNr_hl_groups = { "LineNr", "LineNrAbove", "LineNrBelow" }
		for _, group in ipairs(LineNr_hl_groups) do
			hl[group] = { fg = line_number_color }
		end
		hl.TabLineFill = {
			bg = c.none,
		}
	end,
}
)
vim.cmd("colorscheme tokyonight")
vim.cmd(":hi statusline guibg=NONE")
