{
  lua,
  inputs,
}:
lua.pkgs.buildLuarocksPackage {
  pname = "luacov-reporter-lcov";
  version = "scm-0";
  src = inputs.luacov-reporter-lcov-src;

  patches = [
    ../patches/luacov-reporter-lcov.diff
  ];

  propagatedBuildInputs = [
    lua
  ];
}
