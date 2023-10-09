vim.opt.statusline = "%t"

-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &runtimepath.=','.getcwd()]])

-- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
vim.cmd("set runtimepath+=" .. os.getenv("MINI_NVIM"))

-- Set up 'mini.test'
require("mini.test").setup()
