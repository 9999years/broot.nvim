local MiniTest = require "mini.test"
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local T, child = require("test").new_set { module = "broot.default_directory" }

T["git_root"] = function()
  eq(child.lua_get [[M.git_root()]], vim.trim(vim.fn.system "git rev-parse --show-toplevel"))

  -- In the root directory, we shouldn't have a repo root:
  child.cmd [[ cd / ]]
  eq(child.lua_get [[M.git_root()]], vim.NIL)
end

T["current_file"] = function()
  eq(child.lua_get [[M.current_file()]], vim.fn.expand "%:h")
end

T["current_file_2"] = function()
  child.lua [[
    require("broot").setup {
      default_directory = require("broot.default_directory").current_file
    }
  ]]
  child.cmd [[edit flavors/weenie]]
  eq(child.lua_get [[require("broot").broot()]], vim.NIL)
  vim.loop.sleep(250)
  expect.reference_screenshot(child.get_screenshot())
end

return T
