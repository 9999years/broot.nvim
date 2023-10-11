{stdenv}: args @ {name, ...}: let
  args' = builtins.removeAttrs args ["name"];
in
  stdenv.mkDerivation ({
      name = "broot.nvim-${name}";

      src = ../.;

      dontConfigure = true;
      dontBuild = true;
      doCheck = true;

      installPhase = ''
        touch $out
      '';
    }
    // args')
