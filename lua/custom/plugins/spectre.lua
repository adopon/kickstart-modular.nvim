-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
  {
    'nvim-pack/nvim-spectre',
    build = 'sh build.sh',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      default = {
        replace = { cmd = 'oxi' },
      },
    },
    config = function(_, opts)
      local spectre = require 'spectre'
      spectre.setup(opts)
      vim.keymap.set('n', '<leader>S', spectre.toggle, { desc = 'Toggle Spectre' })
      vim.keymap.set('n', '<leader>sw', function() spectre.open_visual { select_word = true } end, { desc = 'Search current word' })
      vim.keymap.set('v', '<leader>sw', function() spectre.open_visual() end, { desc = 'Search current selection' })
      vim.keymap.set('n', '<leader>sp', function() spectre.open_file_search { select_word = true } end, { desc = 'Search in current file' })
    end,
  },
}
