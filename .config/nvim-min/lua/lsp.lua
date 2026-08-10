local lspServers = {
	"bashls",
	"ts_ls",
	"tailwindcss",
	"dockerls",
	"jsonls",
	"emmet_language_server",
	"lua_ls",
	"basedpyright",
	"gopls",
	"fish_lsp"
}
require("mason-lspconfig").setup({
	ensure_installed = lspServers,
})
vim.lsp.enable(lspServers)
