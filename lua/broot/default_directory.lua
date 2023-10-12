local M = {}

function M.git_root()
  -- Directory of the current file.
  local directory = vim.fn.expand "%:h"
  local repo_root
  local job_id = vim.fn.jobstart({ "git", "rev-parse", "--show-toplevel" }, {
    cwd = directory,
    stdout_buffered = true,
    on_stdout = function(_channel_id, lines, _stream_name)
      if #lines > 0 then
        if vim.fn.isdirectory(lines[1]) == 1 then
          repo_root = lines[1]
        end
      end
    end,
  })
  if job_id == 0 then
    error "Invalid arguments when running `git rev-parse --show-toplevel`"
  elseif job_id == -1 then
    error "`git` is not executable"
  end
  vim.fn.jobwait({ job_id }, -1)
  return repo_root
end

function M.current_file()
  return vim.fn.expand "%:h"
end

return M
