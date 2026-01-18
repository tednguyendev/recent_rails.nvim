describe("config", function()
  local config = require('recent_rails.config')

  it("has FILES table", function()
    assert.is_table(config.FILES)
  end)

  it("has actions file path", function()
    assert.is_string(config.FILES.actions)
    assert.is_true(config.FILES.actions:find("actions") ~= nil)
  end)

  it("has views file path", function()
    assert.is_string(config.FILES.views)
    assert.is_true(config.FILES.views:find("views") ~= nil)
  end)

  it("has errors file path", function()
    assert.is_string(config.FILES.errors)
    assert.is_true(config.FILES.errors:find("errors") ~= nil)
  end)

  it("points to plugin directory", function()
    assert.is_true(config.FILES.actions:find("recent_rails") ~= nil)
  end)

  it("has default opts", function()
    assert.is_table(config.opts)
    assert.is_true(config.opts.auto_watch)
  end)

  it("setup merges opts", function()
    config.setup({ auto_watch = false })
    assert.is_false(config.opts.auto_watch)
    -- Reset
    config.setup({ auto_watch = true })
  end)

  it("has setup function", function()
    assert.is_function(config.setup)
  end)
end)
