local config = require('recent_rails.config')
local utils = require('recent_rails.utils')

return function()
  local entries = utils.read_entries(config.FILES.views)
  if not entries then
    vim.notify("No recent views found.", vim.log.levels.WARN)
    return
  end

  require('telescope.pickers').new({}, {
    prompt_title = 'Recent Views',
    finder = require('telescope.finders').new_table({ results = entries }),
    sorter = require('telescope.config').values.generic_sorter({}),
    previewer = require('telescope.config').values.file_previewer({}),
    initial_mode = 'normal',
    layout_config = {
      height = 0.6,
      width = 0.6,
    },
    attach_mappings = function(prompt_bufnr)
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local path = selection[1]
        if vim.fn.filereadable(path) == 1 then
          vim.cmd('edit ' .. vim.fn.fnameescape(path))
        else
          vim.notify("File not found: " .. path, vim.log.levels.WARN)
        end
      end)
      return true
    end,
  }):find()
end
