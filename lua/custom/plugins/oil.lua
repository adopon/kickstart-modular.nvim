---@module 'lazy'
---@type LazySpec
return {
  {
    'stevearc/oil.nvim',
    dependencies = { { 'echasnovski/mini.icons' } },
    lazy = false,
    config = function()
      local detail = false
      require('oil').setup {
        default_file_explorer = true,
        columns = { 'icon' },
        buf_options = {
          buflisted = false,
          bufhidden = 'hide',
        },
        win_options = {
          wrap = false,
          signcolumn = 'no',
          cursorcolumn = false,
          foldcolumn = '0',
          spell = false,
          list = false,
          conceallevel = 3,
          concealcursor = 'nvic',
        },
        delete_to_trash = false,
        skip_confirm_for_simple_edits = false,
        prompt_save_on_select_new_entry = true,
        cleanup_delay_ms = 2000,
        lsp_file_methods = {
          enabled = true,
          timeout_ms = 1000,
          autosave_changes = false,
        },
        constrain_cursor = 'editable',
        watch_for_changes = false,
        use_default_keymaps = true,
        keymaps = {
          ['<C-h>'] = false,
          ['gd'] = {
            desc = 'Toggle file detail view',
            callback = function()
              detail = not detail
              if detail then
                require('oil').set_columns { 'icon', 'permissions', 'size', 'mtime' }
              else
                require('oil').set_columns { 'icon' }
              end
            end,
          },
        },
        view_options = {
          show_hidden = true,
          natural_order = 'fast',
          case_insensitive = false,
          sort = {
            { 'type', 'asc' },
            { 'name', 'asc' },
          },
        },
        float = {
          padding = 2,
          max_width = 0,
          max_height = 0,
          preview_split = 'auto',
        },
        preview_win = {
          update_on_cursor_moved = true,
          preview_method = 'fast_scratch',
        },
        confirmation = {
          max_width = 0.9,
          min_width = { 40, 0.4 },
          max_height = 0.9,
          min_height = { 5, 0.1 },
        },
        progress = {
          max_width = 0.9,
          min_width = { 40, 0.4 },
          max_height = { 10, 0.9 },
          min_height = { 5, 0.1 },
          minimized_border = 'none',
        },
      }

      vim.keymap.set('n', '<leader>o', require('oil').open, { desc = 'Open Oil' })
      vim.keymap.set('n', '<leader>O', require('oil').open_float, { desc = 'Open Oil floating' })
      -- vim.api.nvim_create_autocmd('User', {
      --   pattern = 'OilActionsPost',
      --   callback = function(event)
      --     if event.data.actions.type == 'move' then
      --       Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
      --     end
      --   end,
      -- })
    end,
  },
}
