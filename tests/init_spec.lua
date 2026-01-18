describe("init", function()
  local recent_rails = require('recent_rails')

  it("exports setup", function()
    assert.is_function(recent_rails.setup)
  end)

  it("setup calls config.setup", function()
    -- Should not error
    recent_rails.setup({ auto_watch = false })
    local config = require('recent_rails.config')
    assert.is_false(config.opts.auto_watch)
    -- Reset
    recent_rails.setup({ auto_watch = true })
  end)
end)
