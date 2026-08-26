local function gh(repo) return 'https://github.com/' .. repo end

-- [[ nvim-spectre ]]
--  Search and replace in a floating window, with a live preview.
--  See `:help spectre` for more information.
vim.pack.add { gh 'nvim-pack/nvim-spectre' }

require('spectre').setup {
  -- See `:help spectre.setup()` for all options
  live_update = true, -- show seach result in realtime while typing
  replace_engine = { ['sed'] = 'sed', ['pwsh'] = 'pwsh', ['node'] = 'node' },
}

-- Recommended keymap
-- Open spectre with the word under the cursor
vim.keymap.set('n', '<leader>S', function() require('spectre').toggle() end, { desc = 'Toggle [S]pectre' })
-- Search for the word under the cursor
vim.keymap.set('n', '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end, { desc = 'Search [w]ord in [S]pectre' })
vim.keymap.set('v', '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end, { desc = 'Search [w]ord in [S]pectre' })
vim.keymap.set('n', '<leader>sW', function() require('spectre').open_file_search() end, { desc = 'Search in current [f]ile' })

-- vim: ts=2 sts=2 sw=2 et
