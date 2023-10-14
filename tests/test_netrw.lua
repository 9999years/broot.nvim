local MiniTest = require "mini.test"
local expect = MiniTest.expect

local T, child = require("test").new_set {
  module = "broot.netrw",
  pre_case = [[
    require("broot").setup {
      replace_netrw = true,
    }
  ]],
}

T["can_explore_side_by_side"] = function()
  child.cmd [[Explore]]
  vim.loop.sleep(250)
  child.cmd [[Lexplore]]
  vim.loop.sleep(250)
  expect.reference_screenshot(child.get_screenshot())
end

return T
