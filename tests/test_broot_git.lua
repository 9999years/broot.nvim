local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/mini_test_init.lua" }
      child.lua([[
        M = require("broot.git")
        vim.cmd("cd tests/data")
      ]])
    end,
    post_once = child.stop,
  },
}

local broot_test = new_set()
T["broot.git"] = broot_test

broot_test["can_compute_repo_root"] = function()
  eq(child.lua_get([[M.repo_root_or_current_directory()]]), vim.trim(vim.fn.system("git rev-parse --show-toplevel")))

  -- In the root directory, we shouldn't have a repo root:
  child.lua([[ vim.cmd("cd /") ]])
  eq(child.lua_get([[M.repo_root_or_current_directory()]]), "/")
end

return T
