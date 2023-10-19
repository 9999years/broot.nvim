{
  mkCheck,
  lualscheck,
  lua-language-server,
}:
mkCheck {
  name = "lua-language-server";
  description = ''
    Check that `lua-language-server` doesn't have any diagnostics in the
    project. Also checks type annotations.
  '';

  nativeCheckInputs = [
    lualscheck
    lua-language-server
  ];

  checkPhase = ''
    lualscheck
  '';
}
