return {
	"rebelot/kanagawa.nvim",
	name = "kanagawa",
	priority = 1000,
	config = function()
		require("kanagawa").setup({
			theme = "wave",
		})
		vim.cmd.colorscheme("kanagawa")

		-- Dim Neovim background when tmux pane loses focus
		local focus_group = vim.api.nvim_create_augroup("TmuxFocusDim", { clear = true })
		vim.api.nvim_create_autocmd("FocusLost", {
			group = focus_group,
			callback = function()
				vim.api.nvim_set_hl(0, "Normal", { bg = "#363646" })
				vim.api.nvim_set_hl(0, "NormalNC", { bg = "#363646" })
			end,
		})
		vim.api.nvim_create_autocmd("FocusGained", {
			group = focus_group,
			callback = function()
				vim.api.nvim_set_hl(0, "Normal", { bg = "#1F1F28" })
				vim.api.nvim_set_hl(0, "NormalNC", { bg = "#1F1F28" })
			end,
		})
	end,
}
