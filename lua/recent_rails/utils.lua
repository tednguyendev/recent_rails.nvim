local M = {}

-- Helper to convert CamelCase to snake_case
function M.to_snake_case(str)
  local segments = {}
  for segment in str:gmatch("[^/]+") do
    local snake = segment:gsub("(%u)", function(c) return "_" .. c:lower() end)
    snake = snake:gsub("^_", "")
    table.insert(segments, snake)
  end
  return table.concat(segments, "/")
end

-- Read entries from a file
function M.read_entries(filepath)
  local expanded = vim.fn.expand(filepath)
  if vim.fn.filereadable(expanded) == 0 then
    return nil
  end
  local entries = vim.fn.readfile(expanded)
  if #entries == 0 then
    return nil
  end
  return entries
end

-- Save entries to file
function M.save_file(path, entries)
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  local f = io.open(path, "w")
  if f then
    f:write(table.concat(entries, "\n") .. "\n")
    f:close()
  end
end

-- Parse controller#action entry and return path info
function M.parse_controller_action(entry)
  local controller, action = entry:match("(.+)#(.+)")
  if controller and action then
    local path = controller:gsub("::", "/")
    path = M.to_snake_case(path)
    path = "app/controllers/" .. path .. ".rb"
    return { path = path, action = action, controller = controller }
  end
  return nil
end

-- Parse error entry and return path info
function M.parse_error_entry(entry)
  local file_line, error_info = entry:match("^([^|]+)|(.+)")
  if not file_line then return nil end

  local path, line = file_line:match("(.+):(%d+)")
  return { path = path, line = tonumber(line), error_info = error_info, file_line = file_line }
end

-- Format error entry for display
function M.format_error_display(entry)
  local file_line, error_info = entry:match("^([^|]+)|(.+)")
  if file_line and error_info then
    local short_path = file_line:gsub("^app/", "")
    local short_error = error_info:sub(1, 60)
    return { display = short_path .. " | " .. short_error, value = entry }
  end
  return nil
end

return M
