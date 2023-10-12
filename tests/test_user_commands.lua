local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T, child = require("test").new_set {
  module = "broot.user_commands",
  pre_case = [[
    require("broot").setup {
      create_user_commands = true,
    }
  ]],
}

T[":Broot"] = function()
  child.cmd([[Broot]])
  vim.loop.sleep(250)
  expect.reference_screenshot(child.get_screenshot())
end

T[":Broot directory"] = function()
  child.cmd([[Broot ./flavors]])
  -- child.cmd([[ Broot flavors ]])
  vim.loop.sleep(250)
  expect.reference_screenshot(child.get_screenshot())
end

return T
