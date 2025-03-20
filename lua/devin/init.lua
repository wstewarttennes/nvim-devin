-- Function to set snapshot and playbook IDs
function M.set_ids(snapshot, playbook)
  M.config.snapshot_id = snapshot
  M.config.playbook_id = playbook
  vim.notify("Snapshot and playbook IDs updated", vim.log.levels.INFO)
end-- Function to test API connection with direct curl command format
function M.test_direct_curl()
  -- Try to load from dotenv first
  load_from_dotenv()
  
  -- Get the API key
  local api_key = M.config.api_key or vim.g.devin_api_key or vim.fn.getenv("DEVIN_API_KEY")
  if api_key == "" or api_key == nil then
    vim.notify("Devin API key not found", vim.log.levels.ERROR)
    return
    -- Add a command to test direct curl format
    vim.api.nvim_create_user_command(
      'DevinTestDirectCurl',
      function()
        M.test_direct_curl()
        -- Add a command to set IDs
    vim.api.nvim_create_user_command(
      'DevinSetIds',
      function(cmd_opts)
        local args = vim.split(cmd_opts.args, " ")
        if #args == 2 then
          M.set_ids(args[1], args[2])
        else
          vim.notify("Usage: DevinSetIds <snapshot_id> <playbook_id>", vim.log.levels.ERROR)
        end
      end,
      {
        nargs = '+',
        desc = 'Set Devin snapshot and playbook IDs',
      }
    )
  end,
      {
        desc = 'Test Devin API with direct curl format',
      }
    )
  end

  -- Create command exactly as in documentation
  local cmd = string.format(
    "curl -X POST \"https://api.devin.ai/v1/sessions\" " ..
    "-H \"Authorization: Bearer %s\" " ..
    "-H \"Content-Type: application/json\" " ..
    "-d '{ \"prompt\": \"Test connection\", \"snapshot_id\": \"%s\", \"playbook_id\": \"%s\" }'",
    api_key,
    M.config.snapshot_id,
    M.config.playbook_id
  )
  
  -- Execute the command
  vim.notify("Testing direct curl command format...", vim.log.levels.INFO)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  
  -- Display the result
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result, "\n"))
  vim.bo[buf].filetype = "json"
  vim.bo[buf].modifiable = false
  vim.cmd("setlocal buftype=nofile")
  vim.api.nvim_buf_set_name(buf, "Devin Direct Curl Test")
end-- Main file for devin.nvim - A Neovim plugin for interacting with the Devin AI API

local M = {}

-- Default configuration
M.config = {
  snapshot_id = "snapshot-7c2dac953e9d4b7593cb3264b64ff724",
  playbook_id = "playbook-787842e7ae7c41db8840b3984f598bc3",
  mappings = {
    visual = "<Leader>dv",
    file = "<Leader>df",
  },
  create_commands = true,
  dotenv_path = nil, -- Path to .env file (optional)
}

-- Function to try loading from dotenv
local function load_from_dotenv()
  local ok, dotenv = pcall(require, 'dotenv')
  if ok then
    -- Try to load from specified path if available
    if M.config.dotenv_path then
      dotenv.load({path = M.config.dotenv_path})
    else
      -- Otherwise try default load
      dotenv.load()
    end
    return true
  end
  return false
end

-- Function to make the API call to Devin
function M.call_devin_api(prompt)
  -- Try to load from dotenv first
  load_from_dotenv()
  
  -- Check for API key in config, global variable, then environment variable
  local api_key = M.config.api_key or vim.g.devin_api_key or vim.fn.getenv("DEVIN_API_KEY")
  if api_key == "" or api_key == nil then
    vim.notify("Devin API key not found. Set in setup config, vim.g.devin_api_key, or DEVIN_API_KEY environment variable", vim.log.levels.ERROR)
    return
  end
  
  -- Debug: Print first few characters of the key
  vim.notify("Using API key starting with: " .. string.sub(api_key, 1, 5) .. "...", vim.log.levels.INFO)

  -- Prepare the command
  local cmd = string.format(
    "curl -s -X POST 'https://api.devin.ai/v1/sessions' " ..
    "-H 'Authorization: Bearer %s' " ..
    "-H 'Content-Type: application/json' " ..
    "-H 'Accept: application/json' " ..
    "-d '{\"prompt\": \"%s\", \"snapshot_id\": \"%s\", \"playbook_id\": \"%s\"}'",
    api_key,
    prompt:gsub('"', '\\"'), -- Escape double quotes
    M.config.snapshot_id,
    M.config.playbook_id
  )
  
  -- Log the command (with masked API key)
  local masked_key = string.sub(api_key, 1, 6) .. "..." .. string.sub(api_key, -4)
  local masked_cmd = string.format(
    "curl -s -X POST 'https://api.devin.ai/v1/sessions' " ..
    "-H 'Authorization: Bearer %s' " ..
    "-H 'Content-Type: application/json' " ..
    "-H 'Accept: application/json' " ..
    "-d '{\"prompt\": \"%s\", \"snapshot_id\": \"%s\", \"playbook_id\": \"%s\"}'",
    masked_key,
    prompt:gsub('"', '\\"'), -- Escape double quotes
    M.config.snapshot_id,
    M.config.playbook_id
  )
  vim.notify("Sending command: " .. masked_cmd, vim.log.levels.DEBUG)

  -- Execute the command with verbose output
  vim.notify("Sending request to Devin API...", vim.log.levels.INFO)
  local handle = io.popen(cmd .. " -v")  -- Add verbose output
  local result = handle:read("*a")
  handle:close()
  
  -- Log error if there's an issue
  if result:match("Invalid auth credentials") then
    vim.notify("API Error: Invalid authentication credentials. Check your API key.", vim.log.levels.ERROR)
  end

  -- Create a new buffer to display the result
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result, "\n"))
  vim.bo[buf].filetype = "json"
  vim.bo[buf].modifiable = false
  vim.cmd("setlocal buftype=nofile")
  vim.api.nvim_buf_set_name(buf, "Devin API Response")
end

-- Create a function to send the current file to Devin
function M.send_current_file()
  local file_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  M.call_devin_api(file_content)
end

-- Create a function to send visual selection to Devin
function M.send_visual_selection()
  local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, '<'))
  local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, '>'))
  
  -- Need to adjust for multibyte characters
  start_col = vim.fn.byteidx(vim.fn.getline(start_line), start_col)
  end_col = vim.fn.byteidx(vim.fn.getline(end_line), end_col)
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return
  end
  
  -- Adjust the first and last line to the proper column range
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col + 1, end_col + 1)
  else
    lines[1] = string.sub(lines[1], start_col + 1)
    lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
  end
  
  local text = table.concat(lines, "\n")
  M.call_devin_api(text)
end

-- Function to set API key directly
function M.set_api_key(key)
  M.config.api_key = key
  vim.notify("API key updated", vim.log.levels.INFO)
end

-- Setup function to configure the plugin and set up keymaps
function M.setup(opts)
  -- Merge user config with defaults
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- Create commands if enabled
  if M.config.create_commands then
    vim.api.nvim_create_user_command(
      'Devin',
      function(cmd_opts)
        M.call_devin_api(cmd_opts.args)
      end,
      {
        nargs = '+',
        desc = 'Call Devin AI API with a prompt',
      }
    )
    
    -- Add a command to set the API key directly
    vim.api.nvim_create_user_command(
      'DevinSetApiKey',
      function(cmd_opts)
        M.set_api_key(cmd_opts.args)
      end,
      {
        nargs = 1,
        desc = 'Set Devin AI API key',
      }
    )
    
    -- Add a command to test API connection
    vim.api.nvim_create_user_command(
      'DevinTestConnection',
      function()
        M.call_devin_api("This is a test connection")
      end,
      {
        desc = 'Test Devin API connection',
      }
    )
  end

  -- Set up keymappings if specified
  if M.config.mappings.visual then
    vim.keymap.set('v', M.config.mappings.visual, M.send_visual_selection, 
      { noremap = true, silent = true, desc = "Send selection to Devin API" })
  end

  if M.config.mappings.file then
    vim.keymap.set('n', M.config.mappings.file, M.send_current_file,
      { noremap = true, silent = true, desc = "Send current file to Devin API" })
  end
end

return M
