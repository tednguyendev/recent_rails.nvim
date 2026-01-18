local M = {}

local config = require('recent_rails.config')
local utils = require('recent_rails.utils')

local SKIP_CONTROLLERS = {
  "Rails::", "ActiveStorage::", "ActionMailbox::", "MissionControl::",
}

local MAX_ENTRIES = 15

-- State
local state = {
  timer = nil,
  log_file = nil,
  last_position = 0,
  actions = {},
  views = {},
  errors = {},
  current_error = nil,
}

-- Check if controller should be skipped
local function should_skip_controller(controller)
  for _, prefix in ipairs(SKIP_CONTROLLERS) do
    if controller:find("^" .. prefix:gsub(":", "%%:")) then
      return true
    end
  end
  return false
end

-- Save error entry
local function save_error(error_data)
  if not error_data.source or not error_data.class then return end

  local entry = error_data.source .. "|" .. error_data.class .. ": " .. error_data.message

  -- Remove if exists, add to front
  for i, e in ipairs(state.errors) do
    if e == entry then
      table.remove(state.errors, i)
      break
    end
  end
  table.insert(state.errors, 1, entry)

  -- Limit entries
  while #state.errors > MAX_ENTRIES do
    table.remove(state.errors)
  end

  utils.save_file(config.FILES.errors, state.errors)
end

-- Save action entry
local function save_action(controller, action)
  if should_skip_controller(controller) then return end

  local entry = controller .. "#" .. action

  for i, e in ipairs(state.actions) do
    if e == entry then
      table.remove(state.actions, i)
      break
    end
  end
  table.insert(state.actions, 1, entry)

  while #state.actions > MAX_ENTRIES do
    table.remove(state.actions)
  end

  utils.save_file(config.FILES.actions, state.actions)
end

-- Check if view should be skipped
local function should_skip_view(view)
  for _, pattern in ipairs(config.opts.skip_views or {}) do
    if view:find(pattern) then
      return true
    end
  end
  return false
end

-- Save view entry
local function save_view(view)
  if should_skip_view(view) then return end

  local full_path = view:find("^app/") and view or ("app/views/" .. view)

  for i, v in ipairs(state.views) do
    if v == full_path then
      table.remove(state.views, i)
      break
    end
  end
  table.insert(state.views, 1, full_path)

  while #state.views > MAX_ENTRIES do
    table.remove(state.views)
  end

  utils.save_file(config.FILES.views, state.views)
end

-- Process a single log line
local function process_line(line)
  -- Strip ANSI codes
  line = line:gsub("\27%[[%d;]*m", "")

  -- Check for error info
  local err_class, err_msg = line:match("Information for.-%s+([A-Z][%w:]+)%s+%((.-)%):")
  if err_class then
    state.current_error = { class = err_class, message = err_msg:sub(1, 100), source = nil }
    return
  end

  -- Check for backtrace if tracking error
  if state.current_error and not state.current_error.source then
    local file, line_num = line:match("(app/[%w/%._-]+%.rb):(%d+)")
    if file then
      state.current_error.source = file .. ":" .. line_num
      save_error(state.current_error)
      state.current_error = nil
      return
    end
  end

  -- Check for inline error
  local inline_class, inline_msg = line:match("([A-Z][%w:]*Error)%s+%((.-)%):")
  if inline_class then
    state.current_error = { class = inline_class, message = inline_msg:sub(1, 100), source = nil }
    return
  end

  -- Check for Processing
  local controller, action = line:match("Processing by ([^#]+)#([%w_]+)")
  if controller and action then
    save_action(controller, action)
    return
  end

  -- Check for Rendered view
  local view = line:match("Rendered ([%w/%._-]+%.html%.[ehrs][rlba][ubim])")
  if view then
    save_view(view)
  end
end

-- Check log file for new content
local function check_log()
  if not state.log_file or vim.fn.filereadable(state.log_file) == 0 then
    return
  end

  local f = io.open(state.log_file, "r")
  if not f then return end

  local size = f:seek("end")

  -- Reset if file was truncated
  if size < state.last_position then
    state.last_position = 0
  end

  if size == state.last_position then
    f:close()
    return
  end

  f:seek("set", state.last_position)

  for line in f:lines() do
    process_line(line)
  end

  state.last_position = f:seek()
  f:close()
end

-- Start watching a log file
function M.start(log_file)
  if state.timer then
    M.stop()
  end

  state.log_file = log_file or "log/development.log"
  state.last_position = 0
  state.current_error = nil

  -- Clear files on start
  utils.save_file(config.FILES.actions, {})
  utils.save_file(config.FILES.views, {})
  utils.save_file(config.FILES.errors, {})

  state.actions = {}
  state.views = {}
  state.errors = {}

  -- Skip to end of file
  local f = io.open(state.log_file, "r")
  if f then
    state.last_position = f:seek("end")
    f:close()
  end

  -- Start timer to poll log file
  state.timer = vim.loop.new_timer()
  state.timer:start(500, 500, vim.schedule_wrap(function()
    check_log()
  end))

  vim.notify("Watching: " .. state.log_file, vim.log.levels.INFO)
end

-- Stop watching
function M.stop()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
    vim.notify("Stopped watching log", vim.log.levels.INFO)
  end
end

-- Check if watching
function M.is_watching()
  return state.timer ~= nil
end

-- Auto-start when entering Rails project
function M.auto_start()
  local log_file = vim.fn.getcwd() .. "/log/development.log"
  if vim.fn.filereadable(log_file) == 1 then
    M.start(log_file)
  end
end

return M
