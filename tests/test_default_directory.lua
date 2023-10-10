local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/mini_test_init.lua" }
      child.lua([[
        M = require("broot.default_directory")
        vim.cmd("cd tests/data")
      ]])
    end,
    post_once = child.stop,
  },
}

local broot_test = new_set()
T["broot.default_directory"] = broot_test

broot_test["git_root"] = function()
  eq(child.lua_get([[M.git_root()]]), vim.trim(vim.fn.system("git rev-parse --show-toplevel")))

  -- In the root directory, we shouldn't have a repo root:
  child.lua([[ vim.cmd("cd /") ]])
  eq(child.lua_get([[M.git_root()]]), vim.NIL)
end

broot_test["current_file"] = function()
  eq(child.lua_get([[M.current_file()]]), vim.fn.expand("%:h"))
end

return T
