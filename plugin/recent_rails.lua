if vim.g.loaded_recent_rails then
  return
end
vim.g.loaded_recent_rails = true

local subcommands = {
  controller = function() require('recent_rails.pickers.actions')() end,
  view = function() require('recent_rails.pickers.views')() end,
  error = function() require('recent_rails.pickers.errors')() end,
}

local function complete(_, cmdline, _)
  local args = vim.split(cmdline, '%s+')
  if #args <= 2 then
    return vim.tbl_keys(subcommands)
  end
  return {}
end

vim.api.nvim_create_user_command('Recent', function(opts)
  local subcmd = opts.fargs[1]
  if subcmd and subcommands[subcmd] then
    subcommands[subcmd]()
  else
    vim.notify('Recent: unknown subcommand. Use: controller, view, error', vim.log.levels.ERROR)
  end
end, {
  nargs = 1,
  complete = complete,
  desc = 'Recent Rails commands',
})

-- Auto-start watcher if in Rails project (deferred)
vim.defer_fn(function()
  local config = require('recent_rails.config')
  if config.opts.auto_watch then
    require('recent_rails.watcher').auto_start()
  end
end, 0)
