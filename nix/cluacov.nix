{
  lua5_1,
  luacov,
  cluacov,
}:
lua5_1.pkgs.buildLuarocksPackage {
  pname = "cluacov";
  version = "scm-1";
  src = cluacov;

  propagatedBuildInputs = [
    lua5_1
    luacov
  ];
}
