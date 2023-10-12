local M = {}

function M.create_user_commands()
  vim.api.nvim_create_user_command("Broot", function(opts)
    local directory = opts.args
    if directory ~= nil then
      directory = vim.fn.expand(directory)
    end
    require("broot").broot { directory = directory }
  end, {
    nargs = "?",
    desc = "Choose a file to open with `broot`",
    complete = "dir",
  })
end

return M
