{
  lib,
  stdenv,
  luarc,
}: let
  mkCheck = args @ {name, ...}: let
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
      // args');
in
  # When this file gets `callPackage`d, `makeOverridable` is called on the
  # result. So we need to give _our_ override attribute a different name so we
  # can use it later.
  args: let
    drv = lib.makeOverridable mkCheck args;
  in
    drv
    // {
      overrideCheck = drv.override;
    }
