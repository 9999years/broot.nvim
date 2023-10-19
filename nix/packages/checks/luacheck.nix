{
  mkCheck,
  lua,
}:
mkCheck {
  name = "luacheck";
  description = ''
    Lint Lua code with `luacheck`.
  '';

  nativeCheckInputs = [lua.pkgs.luacheck];

  checkPhase = ''
    luacheck .
  '';
}
