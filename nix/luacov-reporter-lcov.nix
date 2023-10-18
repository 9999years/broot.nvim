{
  lua5_1,
  luacov-reporter-lcov,
}:
lua5_1.pkgs.buildLuarocksPackage {
  pname = "luacov-reporter-lcov";
  version = "scm-0";
  src = luacov-reporter-lcov;

  patches = [
    ./patches/luacov-reporter-lcov.diff
  ];

  propagatedBuildInputs = [
    lua5_1
  ];
}
