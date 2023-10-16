local M = {}

M.default_config = {}

M.default_config.toml = [=[
[[verbs]]
key = "enter"
invocation = "edit"
shortcut = "e"
apply_to = "file"
external = "broot.nvim edit +{line} {file}"
from_shell = true
]=]

M.default_config.hjson = [[
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
  return vim.fn.sort(vim.tbl_keys(M.default_config))
end

---@param path string
---@return string|nil
function M.is_broot_nvim_config_file(path)
  local basename = vim.fn.fnamemodify(path, ":t:r")
  if basename ~= "nvim" and basename ~= "vim" then
    return nil
  else
    return M.config_file_format(path)
  end
end

function M.config_file_format(path)
  local extension = vim.fn.fnamemodify(path, ":e")
  return extension
end

---@param path string
---@param format string
function M.install_default_config_file(path, format)
  local default_config = M.default_config[format]
  if default_config == nil then
    error(
      "No default config for " .. format .. ". Available formats are: " .. vim.fn.join(default_config_formats(), ",")
    )
  end
  local handle = io.open(path, "w")
  if handle == nil then
    error("Failed to open " .. path)
  end
  handle:write(default_config)
end

---@param config_files string[]
function M.ensure_nvim_config_file(config_files)
  for _i, config_file in pairs(config_files) do
    local maybe_extension = (require("broot").config.is_config_file)(config_file)
    local extension
    if type(maybe_extension) or (type(maybe_extension) == "boolean" and maybe_extension) then
      if type(maybe_extension) == "string" then
        extension = maybe_extension
      else
      end
      if foo then
        M.install_default_config_file(nil, nil)
      end
    end
  end
end

return M
