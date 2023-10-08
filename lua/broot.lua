local M = {
  broot_binary = "broot",
  default_config_file = vim.fn.expand("~/.config/broot/conf.toml"),
  vim_config_file = vim.fn.expand("~/.config/broot/nvim.toml"),
}

function M._config_files()
  return M.default_config_file .. ";" .. M.vim_config_file
end

function M._mktemp()
  local path = vim.fn.tempname()
  if path == nil then
    error("Failed to create tempfile")
  end
  local file = io.open(path, "w")
  if file ~= nil then
    file:close()
  end
  return path
end

function M.broot(opts)
  if opts == nil then
    opts = {}
  end

  -- Create an unlisted `scratch-buffer`.
  local buffer_id = vim.api.nvim_create_buf(false, true)
  if buffer_id == 0 then
    error("Failed to create buffer")
  end
  -- Don't warn when exiting the Broot buffer.
  vim.api.nvim_buf_set_option(buffer_id, "modified", false)

  local window_id = vim.api.nvim_open_win(buffer_id, true, {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.api.nvim_win_get_width(0),
    height = vim.api.nvim_win_get_height(0),
    style = "minimal",
  })
  if window_id == 0 then
    error("Failed to open window")
  end

  if opts.extra_args == nil then
    opts.extra_args = ""
  end

  local cmd_path = M._mktemp()
  local out_path = M._mktemp()
  local cmd = vim.fn.shellescape(M.broot_binary)
    .. " --conf "
    .. vim.fn.shellescape(M._config_files())
    .. " --outcmd "
    .. vim.fn.shellescape(cmd_path)
    .. " "
    .. opts.extra_args
    .. " "
    .. " > "
    .. vim.fn.shellescape(out_path)

  local cmd_opts = {
    on_exit = function(_job_id, exit_code, _event_type)
      M._on_broot_exit(exit_code, window_id, buffer_id, cmd_path, out_path)
    end,
  }

  if opts.directory ~= nil then
    cmd_opts.cwd = opts.directory
  end

  local job_id = vim.fn.termopen(cmd, cmd_opts)
  if job_id == 0 then
    error("Invalid job arguments")
  elseif job_id == -1 then
    error("Broot command is not executable: " .. M.broot_binary)
  end
  vim.cmd(":startinsert")
end

function M._on_broot_exit(exit_code, window_id, buffer_id, cmd_path, out_path)
  if exit_code ~= 0 then
    error("Broot failed with exit code " .. exit_code)
  end
  vim.api.nvim_win_close(window_id, true)
  vim.api.nvim_buf_delete(buffer_id, { force = true })
  M._read_outcmd_path(cmd_path)
  M._read_stdout_path(out_path)
end

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
      vim.api.nvim_cmd({ cmd = "edit", args = { tokens[2] } }, {})
    elseif #tokens > 2 and tokens[1] == "broot.nvim" then
      table.remove(tokens, 1)
      vim.cmd(vim.fn.join(tokens))
    elseif #tokens > 0 then
      vim.api.nvim_cmd({ cmd = "!", args = tokens }, {})
    end
  end
end

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
