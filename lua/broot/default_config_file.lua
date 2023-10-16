local M = {}

M.config_templates = {}

M.config_templates.toml = [=[
[[verbs]]
key = "enter"
invocation = "edit"
shortcut = "e"
apply_to = "file"
external = "broot.nvim edit +{line} {file}"
from_shell = true
]=]

M.config_templates.hjson = [[
verbs: [
    {
        key: "enter"
        invocation: "edit"
        shortcut: "e"
        apply_to: "file"
        external: "broot.nvim edit +{line} {file}"
        from_shell: true
    }
]
]]

---@return string[]
local function default_config_formats()
  return vim.fn.sort(vim.tbl_keys(M.config_templates))
end

---@param path string
---@return string
function M.config_file_format(path)
  local extension = vim.fn.fnamemodify(path, ":e")
  return extension
end

---@param path string
---@param format string
function M.install_default_config_file(path, format)
  local config_template = M.config_templates[format]
  if config_template == nil then
    error(
      "No default broot.nvim config for "
        .. format
        .. ". Available formats are: "
        .. vim.fn.join(default_config_formats(), ",")
    )
  end
  local handle = io.open(path, "w")
  if handle == nil then
    error("Failed to open " .. path)
  end
  handle:write(config_template)
end

---@param path string
function M.write_config_file(path)
  if vim.fn.filereadable(path) then
    -- File already exists, skip.
    return
  end
  local format = M.config_file_format(path)
  M.install_default_config_file(path, format)
end

---@return string
local function config_directory()
  local config = os.getenv "XDG_CONFIG_HOME"
  if config ~= nil then
    return config
  end
  config = os.getenv "BROOT_CONFIG_DIR"
  if config ~= nil then
    return config
  end

  -- TODO: Windows support?
  return vim.fn.expand "~/.config"
end

---@return string[]
function M.detect_config_files()
  local config_files = {}

  local directory = config_directory()
  local basenames = { "conf", "nvim", "vim" }
  local formats = default_config_formats()
  for _, basename in pairs(basenames) do
    for _, format in pairs(formats) do
      local path = directory .. "/" .. basename .. "." .. format
      if vim.fn.filereadable(path) then
        table.insert(config_files, path)
      end
    end
  end

  return config_files
end

return M
