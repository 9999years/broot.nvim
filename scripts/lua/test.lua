local MiniTest = require "mini.test"

local M = {}

function M.new_set(opts)
  local child = MiniTest.new_child_neovim()
  local test_set = MiniTest.new_set {
    hooks = {
      pre_case = function()
        child.restart { "-u", "scripts/mini_test_init.lua" }
        child.lua([[
          M = require("]] .. opts.module .. [[")
        ]] .. (opts.pre_case or "") .. [[
          vim.cmd("cd tests/data")
        ]])
      end,
      post_once = child.stop,
    },
  }

  return test_set, child
end

return M
