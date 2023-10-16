local M = {}

local config = require "broot.config"

M.config = config.config
M.setup = config.setup

---@return string
function M._config_files()
  return vim.fn.join(M.config.config_files, ";")
end

---@return string
function M._mktemp()
  local path = vim.fn.tempname()
  if path == nil then
    error "Failed to create tempfile"
  end
  local file = io.open(path, "w")
  if file ~= nil then
    file:close()
  end
  return path
end

---@class WindowSize
---@field width integer The window width, in columns
---@field height integer The window height, in rows

---@return WindowSize
function M._window_size()
  local height = vim.o.lines - vim.o.cmdheight
  if vim.o.laststatus ~= 0 then
    height = height - 1
  end
  return {
    height = height,
    width = vim.o.columns,
  }
end

---@class BrootOpts
---@field extra_args string[]? A list of extra arguments to pass to broot. These are used in addition to, rather than instead of, the global `extra_args` set with `broot.setup()`.
---@field directory string? The directory to launch broot in. If not given, the `default_directory` function set in `broot.setup()` is used.

---@param opts BrootOpts?
function M.broot(opts)
  if opts == nil then
    opts = {}
  end

  local extra_args = {}
  if opts.extra_args ~= nil then
    extra_args = vim.tbl_map(vim.fn.shellescape, opts.extra_args)
  end

  local cmd_opts = {}

  if opts.directory ~= nil then
    cmd_opts.cwd = opts.directory
  else
    cmd_opts.cwd = M.config.default_directory() or "."
  end

  -- Create an unlisted `scratch-buffer`.
  local buffer_id = vim.api.nvim_create_buf(false, true)
  if buffer_id == 0 then
    error "Failed to create buffer"
  end
  -- Don't warn when exiting the Broot buffer.
  vim.api.nvim_buf_set_option(buffer_id, "modified", false)

  local window_size = M._window_size()

  local window_id = vim.api.nvim_open_win(buffer_id, true, {
    relative = "editor",
    row = 0,
    col = 0,
    width = window_size.width,
    height = window_size.height,
    style = "minimal",
  })
  if window_id == 0 then
    error "Failed to open window"
  end

  local cmd_path = M._mktemp()
  local out_path = M._mktemp()
  local cmd = vim.fn.shellescape(M.config.broot_binary)
    .. " --conf "
    .. vim.fn.shellescape(M._config_files())
    .. " --outcmd "
    .. vim.fn.shellescape(cmd_path)
    .. " "
    .. vim.fn.join(M.config.extra_args)
    .. " "
    .. vim.fn.join(extra_args)
    .. " "
    .. " > "
    .. vim.fn.shellescape(out_path)

  cmd_opts.on_exit = function(_job_id, exit_code, _event_type)
    M._on_broot_exit(exit_code, window_id, buffer_id, cmd_path, out_path)
  end

  local job_id = vim.fn.termopen(cmd, cmd_opts)
  if job_id == 0 then
    error "Invalid job arguments"
  elseif job_id == -1 then
    error("Broot command is not executable: " .. M.broot_binary)
  end
  vim.cmd ":startinsert"

  vim.api.nvim_create_augroup("Broot", {})
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buffer_id,
    group = "Broot",
    nested = true,
    callback = function()
      local window_resize = M._window_size()
      vim.api.nvim_win_set_width(window_id, window_resize.width)
      vim.api.nvim_win_set_height(window_id, window_resize.height)
      -- Moving the cursor back to {1, 0} puts the window where we expect.
      vim.api.nvim_win_set_cursor(window_id, { 1, 0 })
    end,
  })
end

---@param exit_code integer
---@param window_id integer
---@param buffer_id integer
---@param cmd_path string
---@param out_path string
function M._on_broot_exit(exit_code, window_id, buffer_id, cmd_path, out_path)
  if exit_code ~= 0 then
    error("Broot failed with exit code " .. exit_code)
  end
  vim.api.nvim_win_close(window_id, true)
  vim.api.nvim_buf_delete(buffer_id, { force = true })
  M._read_outcmd_path(cmd_path)
  M._read_stdout_path(out_path)
end

---@param cmd_path string
function M._read_outcmd_path(cmd_path)
  local file = io.open(cmd_path)
  if file ~= nil then
    local line = file:read()
    file:close()
    vim.fn.delete(cmd_path)
    if line == nil then
      -- EOF
      return
    end
    local tokens = vim.fn.split(line)
    if #tokens == 2 and tokens[1] == "cd" then
      vim.api.nvim_cmd({ cmd = "cd", args = { tokens[2] } }, {})
    elseif #tokens > 2 and tokens[1] == "broot.nvim" then
      table.remove(tokens, 1)
      vim.cmd(vim.fn.join(tokens))
    elseif #tokens > 0 then
      vim.api.nvim_cmd({ cmd = "!", args = tokens }, {})
    end
  end
end

---@param out_path string
function M._read_stdout_path(out_path)
  local file = io.open(out_path)
  if file ~= nil then
    local line = file:read()
    file:close()
    vim.fn.delete(out_path)
    if line ~= nil and line:len() > 0 and vim.fn.filereadable(line) == 1 then
      vim.api.nvim_cmd({ cmd = "edit", args = { line } }, {})
    end
  end
end

return M
