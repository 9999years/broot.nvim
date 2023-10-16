local M = {}

---@class Config
---@field broot_binary string
---@field extra_args string[]
---@field config_files string[]
---@field default_directory fun(): string?

---@type Config
M.config = {
  broot_binary = "broot",
  extra_args = {},
  config_files = vim.tbl_map(vim.fn.expand, {
    "~/.config/broot/conf.toml",
    "~/.config/broot/nvim.toml",
  }),
  default_directory = vim.fn.getcwd,
}

---@class SetupOpts
---@field broot_binary string? The name of the broot binary to launch.
---@field extra_args string[]? Extra arguments to pass to broot
---@field config_files string[]? Paths to configuration files to pass to broot with the `--conf` argument. Values are passed to `vim.fn.expand` before being stored, so you can use environment variables and `~` in them.
---@field default_directory string|(fun(): string?)|nil `broot.broot()` calls this to determine the directory to launch broot in if the user doesn't supply one explicitly. If this function returns nil, `vim.fn.getcwd()` is used instead.
---@field write_config_file string? A path to write a default configuration file to, if one doesn't already exist. The configuration file will contain the `edit` verb, mapped to `enter`, which will open the focused file in Neovim using `:edit`.
---@field create_user_commands boolean? If true, define the `:Broot` command

---@param opts SetupOpts
function M.setup(opts)
  if opts.config_files ~= nil then
    opts.config_files = vim.tbl_map(vim.fn.expand, opts.config_files)
  end

  -- If `default_directory is a string, wrap it in a function.
  if type(opts.default_directory) == "string" then
    local default_directory = opts.default_directory
    opts.default_directory = function()
      ---@type string
      return default_directory
    end
  end

  if opts.create_user_commands then
    require("broot.user_commands").create_user_commands()
  end

  M.config = vim.tbl_extend("force", M.config, opts)
end

return M
