{
  lua,
  inputs,
  luacov-reporter-lcov,
}:
lua.pkgs.buildLuarocksPackage {
  pname = "luacov";
  version = "scm-1";
  src = inputs.luacov-src;

  propagatedBuildInputs = [
    lua
    luacov-reporter-lcov
  ];

  patches = [
    ../patches/luacov.diff
  ];

  # Tell `luacov` where to find its assets.
  preConfigure = ''
    substituteInPlace src/luacov/reporter/html.lua \
      --subst-var-by assetDir "$out/$rocksSubdir/$pname/$version"
  '';
}
