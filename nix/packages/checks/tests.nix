{
  neovim,
  broot,
  git,
  mkCheck,
  inputs,
}:
mkCheck {
  name = "tests";
  description = ''
    Run unit tests using `mini.nvim`.
  '';

  nativeCheckInputs = [
    neovim
    broot
    git
  ];

  MINI_NVIM = "${inputs.mini-nvim}";

  checkPhase = ''
    git init
    make test
  '';
}
