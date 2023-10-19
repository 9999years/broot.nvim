{
  lua,
  luacov,
  inputs,
}:
lua.pkgs.buildLuarocksPackage {
  pname = "cluacov";
  version = "scm-1";
  src = inputs.cluacov-src;

  propagatedBuildInputs = [
    lua
    luacov
  ];
}
