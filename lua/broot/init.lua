local M = {
  config = {
    broot_binary = "broot",
    extra_args = {},
    config_files = vim.tbl_map(vim.fn.expand, {
      "~/.config/broot/conf.toml",
      "~/.config/broot/nvim.toml",
    }),
    default_directory = vim.fn.getcwd,
  },
}

---@class SetupOpts
---@field broot_binary string? The name of the broot binary to launch.
---@field extra_args string[]? Extra arguments to pass to broot
---@field config_files string[]? Paths to configuration files to pass to broot with the `--conf` argument. Values are passed to `vim.fn.expand` before being stored, so you can use environment variables and `~` in them.
---@field default_directory string|(fun(): string?)|nil `broot.broot()` calls this to determine the directory to launch broot in if the user doesn't supply one explicitly. If this function returns nil, `vim.fn.getcwd()` is used instead.
---@field create_user_commands boolean? If true, define the `:Broot` command
---@field replace_netrw boolean? If true, replace the netrw plugin and `Explore` commands

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

  if opts.replace_netrw then
    require("broot.netrw").replace_netrw()
  end

  M.config = vim.tbl_extend("force", M.config, opts)
end

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

local function reset_cursor(window)
  -- Moving the cursor back to {1, 0} puts the window where we expect.
  vim.api.nvim_win_set_cursor(window, { 1, 0 })
end

local function on_resize(window)
  if vim.api.nvim_win_get_config(window).relative ~= "" then
    -- Resize floating windows to full screen.
    local window_resize = M._window_size()
    vim.api.nvim_win_set_width(window, window_resize.width)
    vim.api.nvim_win_set_height(window, window_resize.height)
  end
  reset_cursor(window)
end

---@class BrootOpts
---@field extra_args string[]? A list of extra arguments to pass to broot. These are used in addition to, rather than instead of, the global `extra_args` set with `broot.setup()`.
---@field directory string? The directory to launch broot in. If not given, the `default_directory` function set in `broot.setup()` is used.
---@field buffer integer? The buffer to launch broot in. If not given, a new buffer is created.
---@field window integer? The window to launch broot in. If not given, a new floating window is opened.

---@param opts BrootOpts?
function M.broot(opts)
  if opts == nil then
    opts = {}
  end

  local extra_args = {}
  if opts.extra_args ~= nil then
    extra_args = vim.tbl_map(vim.fn.shellescape, opts.extra_args)
  end

  local buffer
  if opts.buffer ~= nil then
    ---@type integer
    buffer = opts.buffer
  else
    -- Create an unlisted `scratch-buffer`.
    buffer = vim.api.nvim_create_buf(false, true)
    if buffer == 0 then
      error "Failed to create buffer"
    end
  end
  -- Don't warn when exiting the Broot buffer.
  vim.api.nvim_buf_set_option(buffer, "modified", false)

  local window
  if opts.window ~= nil then
    ---@type window
    window = opts.window
    M._make_window_minimal(window)
    vim.api.nvim_win_set_buf(window, buffer)
  else
    local window_size = M._window_size()
    window = vim.api.nvim_open_win(buffer, true, {
      relative = "editor",
      row = 0,
      col = 0,
      width = window_size.width,
      height = window_size.height,
      style = "minimal",
    })
    if window == 0 then
      error "Failed to open window"
    end
  end

  vim.notify("Launching broot in buffer " .. buffer .. " in window " .. window, vim.log.levels.INFO)

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

  local cmd_opts = {
    on_exit = function(_job_id, exit_code, _event_type)
      M._on_broot_exit(exit_code, window, buffer, cmd_path, out_path)
    end,
  }

  if opts.directory ~= nil then
    cmd_opts.cwd = opts.directory
  else
    cmd_opts.cwd = M.config.default_directory() or "."
  end

  local job_id = vim.fn.termopen(cmd, cmd_opts)
  if job_id == 0 then
    error "Invalid job arguments"
  elseif job_id == -1 then
    error("Broot command is not executable: " .. M.broot_binary)
  end
  vim.cmd ":startinsert"

  local autocmd_group = vim.api.nvim_create_augroup("Broot", { clear = false })
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buffer,
    group = autocmd_group,
    nested = true,
    callback = function()
      on_resize(window)
    end,
  })
  vim.api.nvim_create_autocmd("WinResized", {
    buffer = buffer,
    group = autocmd_group,
    nested = true,
    callback = function()
      for _, resized in ipairs(vim.v.event.windows) do
        on_resize(resized)
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buffer,
    group = autocmd_group,
    nested = true,
    callback = function()
      reset_cursor(window)
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

  vim.api.nvim_buf_delete(buffer_id, { force = true })

  -- Only close the window if it's not the last one.
  if vim.fn.winnr "$" > 1 then
    vim.api.nvim_win_close(window_id, true)
  end

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

---Like the 'minimal' window style but for non-floating windows.
function M._make_window_minimal(window)
  vim.api.nvim_win_set_option(window, "number", false)
  vim.api.nvim_win_set_option(window, "relativenumber", false)
  vim.api.nvim_win_set_option(window, "cursorline", false)
  vim.api.nvim_win_set_option(window, "cursorcolumn", false)
  vim.api.nvim_win_set_option(window, "foldcolumn", "auto")
  vim.api.nvim_win_set_option(window, "spell", false)
  vim.api.nvim_win_set_option(window, "list", false)
  vim.api.nvim_win_set_option(window, "signcolumn", "auto")
  vim.api.nvim_win_set_option(window, "colorcolumn", "")
  vim.api.nvim_win_set_option(window, "statuscolumn", "")

  local fillchars = vim.api.nvim_win_get_option(window, "fillchars")
  if #fillchars == 0 then
    fillchars = "eob: "
  else
    fillchars = fillchars .. ",eob: "
  end
  vim.api.nvim_win_set_option(window, "fillchars", fillchars)

  local winhighlight = vim.api.nvim_win_get_option(window, "winhighlight")
  if #winhighlight == 0 then
    winhighlight = "EndOfBuffer:NONE"
  else
    winhighlight = winhighlight .. ",EndOfBuffer:NONE"
  end

  vim.api.nvim_win_set_option(window, "winhighlight", winhighlight)
end

return M
