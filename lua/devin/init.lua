-- Main file for devin.nvim - A Neovim plugin for interacting with the Devin AI API

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
}

-- Function to make the API call to Devin
function M.call_devin_api(prompt)
  -- Check if DEVIN_API_KEY is set
  local api_key = vim.fn.getenv("DEVIN_API_KEY")
  if api_key == "" then
    vim.notify("DEVIN_API_KEY environment variable not set", vim.log.levels.ERROR)
    return
  end

  -- Prepare the command
  local cmd = string.format(
    "curl -s -X POST 'https://api.devin.ai/v1/sessions' " ..
    "-H 'Authorization: Bearer %s' " ..
    "-H 'Content-Type: application/json' " ..
    "-d '{\"prompt\": \"%s\", \"snapshot_id\": \"%s\", \"playbook_id\": \"%s\"}'",
    api_key,
    prompt:gsub('"', '\\"'), -- Escape double quotes
    M.config.snapshot_id,
    M.config.playbook_id
  )

  -- Execute the command
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()

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
