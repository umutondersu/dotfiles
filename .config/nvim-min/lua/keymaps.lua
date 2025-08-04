-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
local map = vim.keymap.set

map('n', '<leader>o', ':update<CR> :source<CR>', { desc = 'Source File' })
map({ 'n', 'v' }, 'p', '"+p')
map({ 'n', 'v' }, 'P', '"+P')
map({ 'n', 'v' }, 'x', '"+d')
map({ 'n', 'v' }, 'X', '"+D')
map('n', '<leader>f', vim.lsp.buf.format, { desc = "Format Buffer" })
map('n', '<leader>w', ':w<CR>', { desc = 'Save Buffer' })
map('n', '<leader>q', ':bdelete<CR>', { desc = 'Quit Buffer' })
map('i', '<C-x>', vim.lsp.completion.get)

-- Buffer Management
map("n", "<C-a>", '<cmd>enew<cr>', { desc = 'Open a New Buffer' })
map("n", "<bs>", '<cmd>b#<cr>', { desc = 'Reopen Previous Buffer' })

-- New line without insert mode
map('n', '<M-o>', 'o<Esc>', { desc = 'New Line Down' })
map('n', '<M-O>', 'O<Esc>', { desc = 'New Line Up' })

-- window management
map("n", '<c-c>', "<cmd>q<cr>", { desc = 'quit window' })

-- Buffer Navigation
map('n', '<tab>', vim.cmd.bnext, { desc = 'Next Buffer' })
map('n', '<S-Tab>', vim.cmd.bprev, { desc = 'Prev Buffer' })

-- Swap r and ctrl+r
map('n', '<C-r>', 'r', { silent = true }) -- replace a single character
map('n', 'r', '<C-r>', { silent = true }) -- redo

-- keep cursor centered while jumping around
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

map('v', '<', '<gv', { desc = 'Shift Left' })
map('v', '>', '>gv', { desc = 'Shift Right' })

map("n", "<M-u>", ":e!<CR>", { desc = 'Undo all unsaved writes' })

-- Refactor Keymaps
map("n", "<leader>r", function()
	local filepath = vim.fn.expand('%')
	local choice = vim.fn.confirm(
		"Delete " .. vim.fn.fnamemodify(filepath, ":t") .. "?",
		"&Yes\n&No",
		2
	)
	if choice == 1 then
		local success, err = os.remove(filepath)
		if success then
			vim.cmd('bdelete!')
			vim.notify(string.format("Deleted %s", filepath), vim.log.levels.INFO)
		else
			vim.notify(string.format("Failed to delete %s: %s", filepath, err), vim.log.levels.ERROR)
		end
	end
end, { desc = 'Remove File' })
map("n", "<leader>W", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gcI<Left><Left><Left><Left>]],
	{ desc = 'Replace Word' }) -- Replace the word under the cursor
