-- Install all Omarchy theme plugins and aether.nvim (v3) with whatever plugin manager you use. This example is for vim.pack.
vim.pack.add({
	"https://github.com/neanias/everforest-nvim",
	"https://github.com/kepano/flexoki-neovim",
	"https://github.com/ellisonleao/gruvbox.nvim",
	"https://github.com/bjarneo/aether.nvim",
	"https://github.com/bjarneo/hackerman.nvim",
	"https://github.com/rebelot/kanagawa.nvim",
	"https://github.com/omacom-io/lumon.nvim",
	"https://github.com/tahayvr/matteblack.nvim",
	"https://github.com/EdenEast/nightfox.nvim",
	"https://github.com/ribru17/bamboo.nvim",
	"https://github.com/OldJobobo/retro-82.nvim",
	"https://github.com/ficcdaf/ashen.nvim",
	"https://github.com/folke/tokyonight.nvim",
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	{ src = "https://github.com/rose-pine/neovim", name = "rose-pine" },
	{ src = "https://github.com/bjarneo/aether.nvim", version = "v3", name = "aether" },
})

-- Configure aether.nvim. Consult the aether.nvim documentation for available configurations.
require("aether").setup({
	transparent = true,
})
-- Enable aether colorscheme.
vim.cmd.colorscheme("aether")
