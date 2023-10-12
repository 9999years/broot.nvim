local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local T, child = require("test").new_set("broot.default_directory")

T["git_root"] = function()
  eq(child.lua_get([[M.git_root()]]), vim.trim(vim.fn.system("git rev-parse --show-toplevel")))

  -- In the root directory, we shouldn't have a repo root:
  child.lua([[ vim.cmd("cd /") ]])
  eq(child.lua_get([[M.git_root()]]), vim.NIL)
end

T["current_file"] = function()
  eq(child.lua_get([[M.current_file()]]), vim.fn.expand("%:h"))
end

return T
