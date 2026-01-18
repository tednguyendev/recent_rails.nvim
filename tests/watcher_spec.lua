describe("watcher", function()
  local watcher = require('recent_rails.watcher')

  it("has start function", function()
    assert.is_function(watcher.start)
  end)

  it("has stop function", function()
    assert.is_function(watcher.stop)
  end)

  it("has is_watching function", function()
    assert.is_function(watcher.is_watching)
  end)

  it("has auto_start function", function()
    assert.is_function(watcher.auto_start)
  end)

  it("is_watching returns false initially", function()
    assert.is_false(watcher.is_watching())
  end)

  describe("start and stop", function()
    local test_log = "/tmp/test_rails_log.log"

    before_each(function()
      local f = io.open(test_log, "w")
      f:write("")
      f:close()
    end)

    after_each(function()
      watcher.stop()
      os.remove(test_log)
    end)

    it("starts watching a log file", function()
      watcher.start(test_log)
      assert.is_true(watcher.is_watching())
    end)

    it("stops watching", function()
      watcher.start(test_log)
      watcher.stop()
      assert.is_false(watcher.is_watching())
    end)

    it("can restart after stop", function()
      watcher.start(test_log)
      watcher.stop()
      watcher.start(test_log)
      assert.is_true(watcher.is_watching())
    end)
  end)
end)
