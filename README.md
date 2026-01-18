# recent_rails.nvim

A Neovim plugin for quickly navigating to recent Rails actions, views, and errors by watching `log/development.log`.

https://github.com/user-attachments/assets/711a49f1-138f-483b-a4e4-52accadd7ae6

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "tednguyendev/recent_rails.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
}
```

That's it. The plugin auto-detects Rails projects and watches the log file. No setup() required.

## Commands

| Command             | Description                                         |
|---------------------|-----------------------------------------------------|
| `:Recent controller`| Open telescope picker for recent controller actions |
| `:Recent view`      | Open telescope picker for recent views              |
| `:Recent error`     | Open telescope picker for recent errors             |

## Configuration

Configuration is optional. The plugin works without calling setup().

```lua
require("recent_rails").setup({
  auto_watch = true,  -- Auto-start watcher in Rails projects (default: true)
})
```

## Health Check

```vim
:checkhealth recent_rails
```

## Running Tests

```bash
nvim --clean --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

## License

MIT
