local function gh(repo) return 'https://github.com/' .. repo end

-- [[ lazygit.nvim ]]
--  A plugin to open lazygit (a simple terminal UI for git commands) inside Neovim.
--  Requires the `lazygit` executable to be installed separately.
vim.pack.add { gh 'kdheepak/lazygit.nvim' }

-- Keymap to open lazygit
vim.keymap.set('n', '<leader>lg', '<CMD>LazyGit<CR>', { desc = 'Open [L]azy[g]it' })
vim.keymap.set('n', '<leader>gg', '<CMD>LazyGit<CR>', { desc = 'Open Lazy[g]it' })

-- vim: ts=2 sts=2 sw=2 et
