local config = require('recent_rails.config')
local utils = require('recent_rails.utils')

return function()
  local entries = utils.read_entries(config.FILES.actions)
  if not entries then
    vim.notify("No recent actions found.", vim.log.levels.WARN)
    return
  end

  require('telescope.pickers').new({}, {
    prompt_title = 'Recent Actions',
    finder = require('telescope.finders').new_table({ results = entries }),
    sorter = require('telescope.config').values.generic_sorter({}),
    previewer = false,
    initial_mode = 'normal',
    layout_config = {
      height = 0.4,
      width = 0.5,
    },
    attach_mappings = function(prompt_bufnr)
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end

        local parsed = utils.parse_controller_action(selection[1])
        if parsed then
          if vim.fn.filereadable(parsed.path) == 1 then
            vim.cmd('edit ' .. parsed.path)
            local pattern = [[^\s*def\s\+]] .. parsed.action .. [[\>]]
            local result = vim.fn.search(pattern, 'w')
            if result > 0 then
              vim.cmd("normal! zz")
            end
          else
            vim.notify("Controller not found: " .. parsed.path, vim.log.levels.WARN)
          end
        end
      end)
      return true
    end,
  }):find()
end
