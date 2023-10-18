{
  lua5_1,
  luacov,
  luacov-reporter-lcov,
}:
lua5_1.pkgs.buildLuarocksPackage {
  pname = "luacov";
  version = "scm-1";
  src = luacov;

  propagatedBuildInputs = [
    lua5_1
    luacov-reporter-lcov
  ];

  patches = [
    ./patches/luacov.diff
  ];

  # Tell `luacov` where to find its assets.
  preConfigure = ''
    substituteInPlace src/luacov/reporter/html.lua \
      --subst-var-by assetDir "$out/$rocksSubdir/$pname/$version"
  '';
}
