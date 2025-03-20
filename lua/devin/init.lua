-- Main file for devin.nvim - A Neovim plugin for interacting with the Devin AI API

local M = {}

-- Default configuration
M.config = {
  api_key = nil, -- Will be filled from environment variable if not set
  snapshot_id = "snapshot-7c2dac953e9d4b7593cb3264b64ff724",
  playbook_id = "playbook-787842e7ae7c41db8840b3984f598bc3",
  mappings = {
    visual = "<Leader>dv",
    file = "<Leader>df",
  },
  create_commands = true,
  dotenv_path = nil, -- Path to .env file (optional)
  current_session = nil, -- Current active session ID
}

-- Function to try loading from dotenv
local function load_from_dotenv()
  local ok, dotenv = pcall(require, 'dotenv')
  if ok then
    -- Check if dotenv.load exists and is callable
    if type(dotenv.load) == "function" then
      -- Try to load from specified path if available
      if M.config.dotenv_path then
        pcall(dotenv.load, {path = M.config.dotenv_path})
      else
        -- Otherwise try default load
        pcall(dotenv.load)
      end
      return true
    else
      -- Try newer API if available (some versions use setup instead of load)
      if type(dotenv.setup) == "function" then
        if M.config.dotenv_path then
          pcall(dotenv.setup, {path = M.config.dotenv_path})
        else
          pcall(dotenv.setup)
        end
        return true
      end
    end
  end
  return false
end

-- Get API key from available sources
local function get_api_key()
  -- Try to load from dotenv first, but don't fail if it doesn't work
  pcall(load_from_dotenv)
  
  -- Check for API key in config, global variable, then environment variable
  local api_key = M.config.api_key or vim.g.devin_api_key or vim.fn.getenv("DEVIN_API_KEY")
  if api_key == "" or api_key == nil then
    vim.notify("Devin API key not found. Use :DevinSetApiKey to set it directly", vim.log.levels.ERROR)
    return nil
  end
  return api_key .. "="
end

-- Function to create a new Devin session
function M.create_session(prompt, options)
  local api_key = get_api_key()
  if not api_key then return end
  
  options = options or {}
  
  -- Build the JSON payload for session creation
  local payload = {
    prompt = prompt,
    snapshot_id = options.snapshot_id or M.config.snapshot_id,
    playbook_id = options.playbook_id or M.config.playbook_id
  }
  
  -- Add optional parameters if provided
  if options.unlisted ~= nil then payload.unlisted = options.unlisted end
  if options.idempotent ~= nil then payload.idempotent = options.idempotent end
  if options.max_acu_limit ~= nil then payload.max_acu_limit = options.max_acu_limit end
  
  -- Convert payload to JSON
  local json_payload = vim.fn.json_encode(payload)
  
  -- Prepare the command
  local cmd = string.format(
    "curl -s -X POST 'https://api.devin.ai/v1/sessions' " ..
    "-H 'Authorization: Bearer %s' " ..
    "-H 'Content-Type: application/json' " ..
    "-H 'Accept: application/json' " ..
    "-d '%s'",
    api_key,
    json_payload:gsub("'", "'\\''") -- Escape single quotes for shell
  )
  
  -- Log the command (with masked API key)
  local masked_key = string.sub(api_key, 1, 6) .. "..." .. string.sub(api_key, -4)
  local masked_cmd = cmd:gsub(api_key, masked_key)
  vim.notify("Creating Devin session...", vim.log.levels.INFO)
  vim.notify(cmd)
  
  -- Execute the command
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  
  -- Parse the JSON response
  local ok, session_info = pcall(vim.fn.json_decode, result)
  if not ok then
    vim.notify("Failed to parse response: " .. result, vim.log.levels.ERROR)
    return nil
  end
  
  if session_info.session_id then
    -- Store the session ID for future use
    M.config.current_session = session_info.session_id
    vim.notify("Session created: " .. session_info.session_id, vim.log.levels.INFO)
    
    -- Show session URL
    if session_info.url then
      vim.notify("Session URL: " .. session_info.url, vim.log.levels.INFO)
    end
    
    -- Display the response in a new buffer
    M.display_response("Devin Session Created", result)
    
    return session_info
  else
    vim.notify("Failed to create session: " .. result, vim.log.levels.ERROR)
    return nil
  end
end

-- Function to get session details
function M.get_session(session_id)
  local api_key = get_api_key()
  if not api_key then return end
  
  -- Use provided session ID or current session
  session_id = session_id or M.config.current_session
  if not session_id then
    vim.notify("No session ID provided or active session found", vim.log.levels.ERROR)
    return nil
  end
  
  -- Prepare the command
  local cmd = string.format(
    "curl -s -X GET 'https://api.devin.ai/v1/session/%s' " ..
    "-H 'Authorization: Bearer %s' " ..
    "-H 'Accept: application/json'",
    session_id,
    api_key
  )
  
  vim.notify("Getting session details for: " .. session_id, vim.log.levels.INFO)
  
  -- Execute the command
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  
  -- Parse the JSON response
  local ok, session_info = pcall(vim.fn.json_decode, result)
  if not ok then
    vim.notify("Failed to parse response: " .. result, vim.log.levels.ERROR)
    return nil
  end
  
  -- Display the response in a new buffer
  M.display_response("Devin Session Details: " .. session_id, result)
  
  return session_info
end

-- Function to send a message to a session
function M.send_message(message, session_id)
  local api_key = get_api_key()
  if not api_key then return end
  
  -- Use provided session ID or current session
  session_id = session_id or M.config.current_session
  if not session_id then
    vim.notify("No session ID provided or active session found", vim.log.levels.ERROR)
    return nil
  end
  
  -- Build the JSON payload for the message
  local payload = {
    message = message
  }
  
  -- Convert payload to JSON
  local json_payload = vim.fn.json_encode(payload)
  
  -- Prepare the command
  local cmd = string.format(
    "curl -s -X POST 'https://api.devin.ai/v1/session/%s/message' " ..
    "-H 'Authorization: Bearer %s' " ..
    "-H 'Content-Type: application/json' " ..
    "-d '%s'",
    session_id,
    api_key,
    json_payload:gsub("'", "'\\''") -- Escape single quotes for shell
  )
  
  vim.notify("Sending message to session: " .. session_id, vim.log.levels.INFO)
  
  -- Execute the command
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  
  -- The message endpoint returns 204 No Content on success 
  -- So we check if the result is empty
  if result == "" then
    vim.notify("Message sent successfully", vim.log.levels.INFO)
    
    -- After sending a message, automatically get the session details to see the updated state
    vim.defer_fn(function() 
      M.get_session(session_id) 
    end, 1000) -- Wait 1 second before checking session state
    
    return true
  else
    vim.notify("Failed to send message: " .. result, vim.log.levels.ERROR)
    return false
  end
end

-- Function to display a response in a new buffer
function M.display_response(title, content)
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()
  
  -- Check if content is valid JSON and format it
  local formatted_content = content
  local ok, decoded = pcall(vim.fn.json_decode, content)
  if ok then
    formatted_content = vim.fn.json_encode(decoded)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(formatted_content, "\n"))
  vim.bo[buf].filetype = "json"
  vim.bo[buf].modifiable = false
  vim.cmd("setlocal buftype=nofile")
  vim.api.nvim_buf_set_name(buf, title)
end

-- Function to set the active session ID
function M.set_active_session(session_id)
  M.config.current_session = session_id
  vim.notify("Active session set to: " .. session_id, vim.log.levels.INFO)
end

-- Create a function to send the current file to Devin
function M.send_file_to_session(session_id)
  local file_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  M.send_message(file_content, session_id)
end

-- Create a function to send visual selection to Devin
function M.send_selection_to_session(session_id)
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
  M.send_message(text, session_id)
end

-- Function to set API key directly
function M.set_api_key(key)
  M.config.api_key = key
  vim.notify("API key updated", vim.log.levels.INFO)
  
  -- Test the API key immediately
  vim.defer_fn(function()
    local test_cmd = string.format(
      "curl -s -o /dev/null -w '%%{http_code}' -X POST 'https://api.devin.ai/v1/sessions' " ..
      "-H 'Authorization: Bearer %s' " ..
      "-H 'Content-Type: application/json' " ..
      "-d '{\"prompt\": \"test\", \"idempotent\": true}'",
      key
    )
    print(test_cmd)
    local handle = io.popen(test_cmd)
    local status = handle:read("*a")
    handle:close()
    
    if status == "200" or status == "201" then
      vim.notify("API key verified and working", vim.log.levels.INFO)
    else
      vim.notify("API key appears invalid (HTTP status: " .. status .. ")", vim.log.levels.ERROR)
    end
  end, 100)
end

-- Function to set snapshot and playbook IDs
function M.set_ids(snapshot, playbook)
  M.config.snapshot_id = snapshot
  M.config.playbook_id = playbook
  vim.notify("Snapshot and playbook IDs updated", vim.log.levels.INFO)
end

-- Setup function to configure the plugin and set up keymaps
function M.setup(opts)
  -- Merge user config with defaults
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- Create commands if enabled
  if M.config.create_commands then
    -- Session management commands
    vim.api.nvim_create_user_command(
      'DevinCreateSession',
      function(cmd_opts)
        -- If API key isn't working, prompt the user to enter it directly
        if not get_api_key() then
          vim.ui.input({
            prompt = "Enter Devin API Key: ",
          }, function(input)
            if input and input ~= "" then
              M.config.api_key = input
              vim.notify("Using provided API key for this command", vim.log.levels.INFO)
              M.create_session(cmd_opts.args)
            end
          end)
        else
          M.create_session(cmd_opts.args)
        end
      end,
      {
        nargs = '+',
        desc = 'Create a new Devin session with a prompt',
      }
    )
    
    vim.api.nvim_create_user_command(
      'DevinGetSession',
      function(cmd_opts)
        local session_id = cmd_opts.args ~= "" and cmd_opts.args or nil
        M.get_session(session_id)
      end,
      {
        nargs = '?',
        desc = 'Get details for a Devin session',
      }
    )
    
    vim.api.nvim_create_user_command(
      'DevinSendMessage',
      function(cmd_opts)
        M.send_message(cmd_opts.args)
      end,
      {
        nargs = '+',
        desc = 'Send a message to the active Devin session',
      }
    )
    
    vim.api.nvim_create_user_command(
      'DevinSetActiveSession',
      function(cmd_opts)
        M.set_active_session(cmd_opts.args)
      end,
      {
        nargs = 1,
        desc = 'Set the active Devin session ID',
      }
    )
    
    -- Configuration commands
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
  end

  -- Set up keymappings if specified
  if M.config.mappings.visual then
    vim.keymap.set('v', M.config.mappings.visual, function()
      M.send_selection_to_session()
    end, { noremap = true, silent = true, desc = "Send selection to active Devin session" })
  end

  if M.config.mappings.file then
    vim.keymap.set('n', M.config.mappings.file, function()
      M.send_file_to_session()
    end, { noremap = true, silent = true, desc = "Send current file to active Devin session" })
  end
end

return M
