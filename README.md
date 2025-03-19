# devin.nvim

A Neovim plugin for interacting with the [Devin AI API](https://api.devin.ai).

## Features

- Send prompts to Devin AI API directly from Neovim
- Send visual selections or entire files as context
- Customizable keybindings
- View API responses in a separate buffer

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "yourusername/devin.nvim",
  config = function()
    require("devin").setup({
      -- Optional custom configuration
      mappings = {
        visual = "<Leader>dv", -- Send visual selection to Devin
        file = "<Leader>df",   -- Send entire file to Devin
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/devin.nvim',
  config = function()
    require('devin').setup()
  end
}
```

## Configuration

You can customize the plugin by passing configuration options to the setup function:

```lua
require('devin').setup({
  snapshot_id = "your-custom-snapshot-id",
  playbook_id = "your-custom-playbook-id",
  mappings = {
    visual = "<Leader>dv",
    file = "<Leader>df",
  },
  create_commands = true, -- Whether to create :Devin command
})
```

## Usage

1. Make sure you have the `DEVIN_API_KEY` environment variable set with your API key

2. Use the `:Devin` command followed by your prompt:
   ```
   :Devin I need help optimizing this React component
   ```

3. Use visual selection and press `<Leader>dv` to send the selected text to Devin

4. Use `<Leader>df` to send the entire current file to Devin

## License

MIT
