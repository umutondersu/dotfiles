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

vim.api.nvim_create_user_command('Gc', function(args)
	local vimCmd = 'Git commit'
	if args['args'] then
		vimCmd = vimCmd .. ' -m "' .. args['args'] .. '"'
	end
	vim.cmd(vimCmd)
end, { desc = 'Commit w/wo a message', nargs = '*' })

vim.api.nvim_create_user_command('Gp', function(args)
	local vimCmd = 'Git push'
	if args['args'] then
		vimCmd = vimCmd .. ' ' .. args['args']
	end
	vim.cmd(vimCmd)
end, { desc = 'Git push', nargs = '*' })

vim.api.nvim_create_user_command('Gpf', function()
	local vimCmd = 'Git push --force'
	vim.cmd(vimCmd)
end, { desc = 'Git push --force', nargs = '*' })

vim.api.nvim_create_user_command('Grc', function()
	local vimCmd = 'Git recommit'
	vim.cmd(vimCmd)
end, { desc = 'Git recommit', nargs = '*' })
