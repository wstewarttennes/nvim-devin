-- plugin/devin.lua
-- This file ensures the plugin can be loaded automatically by Neovim

-- Avoid loading the plugin multiple times
if vim.g.loaded_devin_nvim == 1 then
  return
end
vim.g.loaded_devin_nvim = 1

-- The actual plugin initialization is handled by the setup function
-- This stub ensures the plugin is available but doesn't automatically
-- initialize until the user calls setup()

-- Note: When using a plugin manager like lazy.nvim or packer.nvim,
-- you typically call setup() in your configuration anyway, so this
-- file mostly serves to mark the plugin as properly structured.

-- If you want to load the plugin with default settings automatically 
-- without requiring a setup() call, uncomment the following line:
-- require('devin').setup()
