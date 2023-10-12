local MiniTest = require("mini.test")
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local T, child = require("test").new_set("broot")

T["can_open_file"] = function()
  eq(child.lua_get([[M.broot()]]), vim.NIL)
  vim.loop.sleep(250)
  child.type_keys(100, "sam", "<CR>")
  vim.loop.sleep(250)
  expect.reference_screenshot(child.get_screenshot())
end

T["can_use_directory"] = function()
  eq(child.lua_get([[M.broot{directory = "flavors"}]]), vim.NIL)
  vim.loop.sleep(250)
  expect.reference_screenshot(child.get_screenshot())
end

T["can_use_git_root_directory"] = function()
  child.lua([[
    M.setup {
      default_directory = require("broot.default_directory").git_root
    }
  ]])
  eq(child.lua_get([[M.broot{directory = M.GIT_ROOT}]]), vim.NIL)
  vim.loop.sleep(250)
  child.type_keys(100, " cd", "<CR>")
  vim.loop.sleep(250)
  eq(child.lua_get([[vim.fn.getcwd()]]), vim.trim(vim.fn.system("git rev-parse --show-toplevel")))
end

T["can_use_extra_args"] = function()
  eq(child.lua_get([[M.broot{extra_args = {"--cmd", "c/sam"}}]]), vim.NIL)
  vim.loop.sleep(250)
  expect.reference_screenshot(child.get_screenshot())
end

T["can_resize"] = function()
  child.o.lines = 35
  child.o.columns = 100
  eq(child.lua_get([[M.broot()]]), vim.NIL)
  vim.loop.sleep(250)

  child.o.lines = 24
  child.o.columns = 40
  vim.loop.sleep(250)
  expect.reference_screenshot(child.get_screenshot())
end

return T
