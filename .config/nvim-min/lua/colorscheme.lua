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
vim.cmd("colorscheme tokyonight-night")
vim.cmd(":hi statusline guibg=NONE")
