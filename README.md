# nvim-devin

A Neovim plugin for interacting with the [Devin AI API](https://api.devin.ai).

## Features

- Create and manage Devin AI sessions
- Send messages to Devin sessions
- View session details and responses
- Send visual selections or entire files as messages
- Customizable keybindings
- View API responses in separate buffers

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
      dotenv_path = vim.fn.stdpath("config") .. "/.env"  -- Path to .env file containing DEVIN_API_KEY
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
  api_key = "your-devin-api-key", -- Optional: Set your API key here (not recommended for shared configs)
  snapshot_id = "your-custom-snapshot-id",
  playbook_id = "your-custom-playbook-id",
  mappings = {
    visual = "<Leader>dv",
    file = "<Leader>df",
  },
  create_commands = true, -- Whether to create commands
  dotenv_path = "path/to/your/.env" -- Custom path to .env file
})
```

## Setting your API key

You have three options to set your Devin API key:

1. **Environment variable (recommended)**: Set the `DEVIN_API_KEY` environment variable
   ```bash
   export DEVIN_API_KEY="your_api_key_here"
   ```

2. **Neovim global variable**: Set it in your config before calling setup
   ```lua
   vim.g.devin_api_key = "your_api_key_here"
   require('devin').setup()
   ```

3. **Configuration option**: Pass it directly in setup (not recommended for shared configs)
   ```lua
   require('devin').setup({
     api_key = "your_api_key_here",
   })
   ```

4. **Using dotenv.nvim**: Store your API key in a `.env` file
   ```
   DEVIN_API_KEY=your_api_key_here
   ```
   And make sure to install and configure [dotenv.nvim](https://github.com/ellisonleao/dotenv.nvim)

## Usage

### Session Management

1. Create a new session:
   ```
   :DevinCreateSession Write a script to analyze log files
   ```

2. Get session details (uses active session if none specified):
   ```
   :DevinGetSession
   :DevinGetSession devin-session-id
   ```

3. Set the active session:
   ```
   :DevinSetActiveSession devin-session-id
   ```

4. Send a message to the active session:
   ```
   :DevinSendMessage Let's focus on performance optimization
   ```

### Sending Content to a Session

1. Send visually selected text to the active session:
   - Select text in visual mode (v)
   - Press `<Leader>dv` (default)

2. Send the entire current file to the active session:
   - Press `<Leader>df` (default)

### Configuration Commands

1. Set your API key:
   ```
   :DevinSetApiKey your-api-key-here
   ```

2. Set custom snapshot and playbook IDs:
   ```
   :DevinSetIds snapshot-id playbook-id
   ```

## License

MIT
