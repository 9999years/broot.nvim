local M = {}

function M.replace_netrw()
  local group_id = vim.api.nvim_create_augroup("BrootNetrw", {})
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group_id,
    desc = "Clear the FileExplorer group",
    callback = function(_event)
      vim.api.nvim_clear_autocmds {
        group = "FileExplorer",
      }
      vim.api.nvim_create_augroup("FileExplorer", {})
      M._replace_netrw_commands()
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group_id,
    desc = "Use Broot to browse directories",
    callback = function(event)
      if vim.fn.isdirectory(event.file) == 1 then
        require("broot").broot {
          buffer = event.buf,
          window = vim.fn.win_getid(),
          directory = event.file,
        }
      end
    end,
  })

  M._replace_netrw_commands()
end

function M._replace_netrw_commands()
  local current_file = require("broot.default_directory").current_file()

  vim.api.nvim_create_user_command("Explore", function(opts)
    require("broot").broot {
      directory = opts.args or current_file(),
      window = vim.fn.win_getid(),
    }
  end, {
    nargs = "?",
    desc = "Explore the given directory with broot",
  })

  vim.api.nvim_create_user_command("Hexplore", function(opts)
    vim.cmd [[split]]
    require("broot").broot {
      directory = opts.args or current_file(),
      window = vim.fn.win_getid(),
    }
  end, {
    nargs = "?",
    desc = "Explore the given directory with broot",
  })

  vim.api.nvim_create_user_command("Vexplore", function(opts)
    vim.cmd [[vsplit]]
    require("broot").broot {
      directory = opts.args or current_file(),
      window = vim.fn.win_getid(),
    }
  end, {
    nargs = "?",
    desc = "Explore the given directory with broot",
  })

  vim.api.nvim_create_user_command("Lexplore", function(opts)
    vim.cmd [[leftabove vsplit]]
    require("broot").broot {
      directory = opts.args or current_file(),
      window = vim.fn.win_getid(),
    }
  end, {
    nargs = "?",
    desc = "Explore the given directory with broot",
  })

  vim.api.nvim_create_user_command("Sexplore", function(opts)
    vim.cmd [[leftabove split]]
    require("broot").broot {
      directory = opts.args or current_file(),
      window = vim.fn.win_getid(),
    }
  end, {
    nargs = "?",
    desc = "Explore the given directory with broot",
  })

  vim.api.nvim_create_user_command("Texplore", function(opts)
    vim.cmd [[tabnew]]
    require("broot").broot {
      directory = opts.args or current_file(),
      window = vim.fn.win_getid(),
      buffer = vim.fn.bufnr(),
    }
  end, {
    nargs = "?",
    desc = "Explore the given directory with broot",
  })
end

return M
