describe("utils", function()
  local utils = require('recent_rails.utils')

  describe("to_snake_case", function()
    it("converts CamelCase to snake_case", function()
      assert.are.equal("users_controller", utils.to_snake_case("UsersController"))
    end)

    it("converts nested CamelCase paths", function()
      assert.are.equal("api/v1/users_controller", utils.to_snake_case("Api/V1/UsersController"))
    end)

    it("handles single word", function()
      assert.are.equal("users", utils.to_snake_case("Users"))
    end)

    it("handles already snake_case", function()
      assert.are.equal("users_controller", utils.to_snake_case("users_controller"))
    end)

    it("handles multiple uppercase in sequence", function()
      assert.are.equal("a_p_i_controller", utils.to_snake_case("APIController"))
    end)

    it("handles empty string", function()
      assert.are.equal("", utils.to_snake_case(""))
    end)

    it("handles deeply nested paths", function()
      assert.are.equal("admin/api/v2/users_controller", utils.to_snake_case("Admin/Api/V2/UsersController"))
    end)
  end)

  describe("parse_controller_action", function()
    it("parses simple controller#action", function()
      local result = utils.parse_controller_action("UsersController#index")
      assert.are.equal("app/controllers/users_controller.rb", result.path)
      assert.are.equal("index", result.action)
      assert.are.equal("UsersController", result.controller)
    end)

    it("parses namespaced controller#action", function()
      local result = utils.parse_controller_action("Api::V1::UsersController#show")
      assert.are.equal("app/controllers/api/v1/users_controller.rb", result.path)
      assert.are.equal("show", result.action)
      assert.are.equal("Api::V1::UsersController", result.controller)
    end)

    it("parses deeply namespaced controller", function()
      local result = utils.parse_controller_action("Admin::Api::V2::OrdersController#create")
      assert.are.equal("app/controllers/admin/api/v2/orders_controller.rb", result.path)
      assert.are.equal("create", result.action)
    end)

    it("returns nil for invalid format", function()
      local result = utils.parse_controller_action("invalid")
      assert.is_nil(result)
    end)

    it("returns nil for empty string", function()
      local result = utils.parse_controller_action("")
      assert.is_nil(result)
    end)

    it("handles action with underscores", function()
      local result = utils.parse_controller_action("UsersController#update_password")
      assert.are.equal("update_password", result.action)
    end)
  end)

  describe("parse_error_entry", function()
    it("parses error entry with file:line|message format", function()
      local result = utils.parse_error_entry("app/models/user.rb:42|NoMethodError: undefined method 'foo'")
      assert.are.equal("app/models/user.rb", result.path)
      assert.are.equal(42, result.line)
      assert.are.equal("NoMethodError: undefined method 'foo'", result.error_info)
    end)

    it("parses error with absolute path", function()
      local result = utils.parse_error_entry("/Users/test/app/models/user.rb:100|SyntaxError: unexpected end")
      assert.are.equal("/Users/test/app/models/user.rb", result.path)
      assert.are.equal(100, result.line)
    end)

    it("returns nil for invalid format", function()
      local result = utils.parse_error_entry("invalid error format")
      assert.is_nil(result)
    end)

    it("returns nil for empty string", function()
      local result = utils.parse_error_entry("")
      assert.is_nil(result)
    end)

    it("handles complex error messages with pipes", function()
      local result = utils.parse_error_entry("app/models/user.rb:10|Error: something | with | pipes")
      assert.are.equal("app/models/user.rb", result.path)
      assert.are.equal(10, result.line)
      assert.are.equal("Error: something | with | pipes", result.error_info)
    end)
  end)

  describe("format_error_display", function()
    it("formats error for display", function()
      local result = utils.format_error_display("app/models/user.rb:42|NoMethodError: undefined method")
      assert.are.equal("models/user.rb:42 | NoMethodError: undefined method", result.display)
      assert.are.equal("app/models/user.rb:42|NoMethodError: undefined method", result.value)
    end)

    it("truncates long error messages", function()
      local long_error = "app/models/user.rb:1|" .. string.rep("a", 100)
      local result = utils.format_error_display(long_error)
      assert.is_true(#result.display <= 80)
    end)

    it("returns nil for invalid format", function()
      local result = utils.format_error_display("invalid")
      assert.is_nil(result)
    end)

    it("removes app/ prefix from path", function()
      local result = utils.format_error_display("app/controllers/users_controller.rb:10|Error")
      assert.is_true(result.display:find("^controllers/") ~= nil)
    end)
  end)

  describe("read_entries", function()
    local test_file = "/tmp/test_recent_rails_entries.txt"

    before_each(function()
      os.remove(test_file)
    end)

    after_each(function()
      os.remove(test_file)
    end)

    it("reads entries from file", function()
      local f = io.open(test_file, "w")
      f:write("line1\nline2\nline3")
      f:close()

      local entries = utils.read_entries(test_file)
      assert.are.equal(3, #entries)
      assert.are.equal("line1", entries[1])
      assert.are.equal("line2", entries[2])
      assert.are.equal("line3", entries[3])
    end)

    it("returns nil for non-existent file", function()
      local entries = utils.read_entries("/tmp/nonexistent_file_12345.txt")
      assert.is_nil(entries)
    end)

    it("returns nil for empty file", function()
      local f = io.open(test_file, "w")
      f:write("")
      f:close()

      local entries = utils.read_entries(test_file)
      assert.is_nil(entries)
    end)

    it("expands ~ in filepath", function()
      local entries = utils.read_entries("~/nonexistent_test_file.txt")
      assert.is_nil(entries)
    end)
  end)

  describe("save_file", function()
    local test_file = "/tmp/test_recent_rails_save.txt"

    after_each(function()
      os.remove(test_file)
    end)

    it("saves entries to file", function()
      utils.save_file(test_file, {"line1", "line2", "line3"})
      local entries = utils.read_entries(test_file)
      assert.are.equal(3, #entries)
      assert.are.equal("line1", entries[1])
    end)

    it("handles empty table", function()
      utils.save_file(test_file, {})
      local f = io.open(test_file, "r")
      local content = f:read("*a")
      f:close()
      assert.are.equal("\n", content)
    end)
  end)

end)
