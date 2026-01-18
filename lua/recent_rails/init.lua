local M = {}

-- Setup function (optional - plugin works without it)
function M.setup(opts)
  require('recent_rails.config').setup(opts)
end

return M
