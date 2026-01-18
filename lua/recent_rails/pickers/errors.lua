local config = require('recent_rails.config')
local utils = require('recent_rails.utils')

return function()
  local entries = utils.read_entries(config.FILES.errors)
  if not entries then
    vim.notify("No recent errors found.", vim.log.levels.WARN)
    return
  end

  local display_entries = {}
  for _, e in ipairs(entries) do
    local formatted = utils.format_error_display(e)
    if formatted then
      table.insert(display_entries, formatted)
    end
  end

  require('telescope.pickers').new({}, {
    prompt_title = 'Recent Errors',
    finder = require('telescope.finders').new_table({
      results = display_entries,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.display,
          ordinal = entry.display,
        }
      end,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),
    previewer = false,
    initial_mode = 'normal',
    layout_config = {
      height = 0.5,
      width = 0.8,
    },
    attach_mappings = function(prompt_bufnr)
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then return end

        local parsed = utils.parse_error_entry(selection.value)
        if not parsed then return end

        if parsed.path and vim.fn.filereadable(parsed.path) == 1 then
          vim.cmd('edit ' .. vim.fn.fnameescape(parsed.path))
          vim.cmd(':' .. parsed.line)
          vim.cmd("normal! zz")
          vim.notify(parsed.error_info, vim.log.levels.ERROR)
        else
          vim.notify("File not found: " .. (parsed.path or parsed.file_line), vim.log.levels.WARN)
        end
      end)
      return true
    end,
  }):find()
end
