vim.opt.statusline = "%t"

-- Add current directory to 'runtimepath' to be able to use 'lua' files
-- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
local mini_nvim = os.getenv "MINI_NVIM"
if mini_nvim == nil then
  error "$MINI_NVIM is not set; are you in the `nix develop` shell?"
end
local cwd = vim.fn.getcwd()
vim.opt.runtimepath:append("," .. vim.fn.join({ cwd, cwd .. "/scripts", mini_nvim }, ","))

-- Set up 'mini.test'
require("mini.test").setup()

require("broot").setup {
  config_files = {
    vim.fn.fnamemodify("tests/data/conf.toml", ":p"),
    vim.fn.fnamemodify("tests/data/nvim.toml", ":p"),
  },
}
