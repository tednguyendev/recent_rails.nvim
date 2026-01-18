local M = {}

-- Get project-specific data directory
local function get_data_dir()
  local cwd = vim.fn.getcwd()
  -- Use base64-like encoding of cwd to create unique folder name
  local project_id = vim.fn.sha256(cwd):sub(1, 12)
  return vim.fn.stdpath('cache') .. '/recent_rails/' .. project_id
end

-- File paths for storing recent data (computed lazily)
M.FILES = setmetatable({}, {
  __index = function(_, key)
    local data_dir = get_data_dir()
    local files = {
      actions = data_dir .. "/actions",
      views = data_dir .. "/views",
      errors = data_dir .. "/errors",
    }
    return files[key]
  end
})

-- Default options
local defaults = {
  auto_watch = true,
  skip_views = { "layouts/", "shared/" },
}

-- Current options (merged with user opts)
M.opts = vim.deepcopy(defaults)

-- Setup config with validation
function M.setup(opts)
  opts = opts or {}

  local ok, err = pcall(vim.validate, {
    auto_watch = { opts.auto_watch, 'boolean', true },
  })

  if not ok then
    vim.notify('recent_rails: invalid config: ' .. err, vim.log.levels.ERROR)
    return
  end

  M.opts = vim.tbl_deep_extend('force', defaults, opts)
end

return M
