local M = {}

-- User-configurable: filetype -> shell command (stdin/stdout)
M.formatters = {
	lua = "stylua -",
	go = "golangci-lint fmt --stdin",
	javascript = "biome format --stdin-file-path=%",
	typescript = "biome format --stdin-file-path=%",
	typescriptreact = "biome format --stdin-file-path=%",
	json = "biome format --stdin-file-path=%",
	python = "isort - | black - 2>/dev/null",
	nix = "nixfmt -",
	yaml = "yamlfmt -",
}

vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function(args)
		local bufnr = args.buf
		local ft = vim.bo[bufnr].filetype
		local cmd = M.formatters[ft]

		-- LSP Formatting
		for _, cl in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
			if cl:supports_method("textDocument/formatting") then
				vim.lsp.buf.format({ bufnr = bufnr, async = false })
				break
			end
		end

		-- Return early if no formatter assigned
		if not cmd then
			return
		end

		-- Replace % with actual buffer path for tools that need it
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		local resolved = cmd:gsub("%%", bufname)

		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local input = table.concat(lines, "\n")

		local output = vim.fn.system(resolved, input)

		if vim.v.shell_error == 0 then
			local formatted = vim.split(output, "\n", { plain = true })
			-- Remove trailing empty line that shell commands often append
			if formatted[#formatted] == "" then
				table.remove(formatted)
			end
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
		end
	end,
})

return M
