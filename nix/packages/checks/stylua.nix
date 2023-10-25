{
  mkCheck,
  stylua,
}:
mkCheck {
  name = "stylua";
  description = ''
    Lua code formatting with `stylua`.
  '';

  nativeCheckInputs = [
    stylua
  ];

  checkPhase = ''
    stylua --check .
  '';
}
