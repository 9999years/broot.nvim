require("broot").setup {
  config_files = {
    vim.fn.fnamemodify("tests/data/conf.toml", ":p"),
    vim.fn.fnamemodify("tests/data/nvim.toml", ":p"),
  },
}
