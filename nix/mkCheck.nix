{
  stdenv,
  luarc,
}: args @ {name, ...}: let
  args' = builtins.removeAttrs args ["name"];
in
  stdenv.mkDerivation ({
      name = "broot.nvim-${name}";

      src = ../.;

      dontConfigure = true;
      dontBuild = true;
      doCheck = true;

      postPatch = ''
        export HOME=$(pwd)
        ${luarc.link-to-cwd}
      '';

      installPhase = ''
        touch $out
      '';
    }
    // args')
