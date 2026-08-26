local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Oil.nvim ]]
--  File explorer that edits your filesystem like a normal Neovim buffer.
--  See `:help oil` for more information.
vim.pack.add { gh 'stevearc/oil.nvim' }

-- Optional dependencies for Oil
vim.pack.add {
  gh 'stevearc/dressing.nvim', -- Improves the default vim.ui interfaces
  gh 'nvim-lua/plenary.nvim', -- General dependency
  gh 'nvim-tree/nvim-web-devicons', -- Icons (or use the mini.icons mock)
}

require('oil').setup {
  -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
  default_file_explorer = true,
  -- Id is automatically added at the beginning, otherwise it's good to explicitly add it
  view_options = {
    show_hidden = true,
  },
  keymaps = {
    ['g?'] = 'actions.show_help',
    ['<CR>'] = 'actions.select',
    ['<C-s>'] = { 'actions.select', opts = { vertical = true } },
    ['<C-h>'] = { 'actions.select', opts = { horizontal = true } },
    ['<C-t>'] = { 'actions.select', opts = { tab = true } },
    ['<C-p>'] = 'actions.preview',
    ['<C-c>'] = 'actions.close',
    ['<C-l>'] = 'actions.refresh',
    ['-'] = 'actions.parent',
    ['_'] = 'actions.open_cwd',
    ['`'] = 'actions.cd',
    ['~'] = { 'actions.cd', opts = { scope = 'tab' } },
    ['gs'] = 'actions.change_sort',
    ['gx'] = 'actions.open_external',
    ['g.'] = 'actions.toggle_hidden',
  },
}

-- Recommended keymaps
vim.keymap.set('n', '<leader>o', '<CMD>Oil<CR>', { desc = 'Open oil' })
-- Open the parent directory and switch to it in the current window
vim.keymap.set('n', '<leader>-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
-- Open the parent directory in a split
vim.keymap.set('n', '<leader>od', '<CMD>Oil --view=split<CR>', { desc = 'Open parent directory in a [s]plit' })
-- Open the current working directory
vim.keymap.set('n', '<leader>o.', '<CMD>Oil .<CR>', { desc = 'Open current directory' })

-- vim: ts=2 sts=2 sw=2 et
