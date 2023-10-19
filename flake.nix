{
  description = "Broot integration for neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    # Neovim test framework.
    mini-nvim = {
      url = "github:echasnovski/mini.nvim";
      flake = false;
    };

    # Vimhelp->HTML generation. Used for the GitHub pages site.
    vimhelp-src = {
      url = "github:c4rlo/vimhelp";
      flake = false;
    };

    # Tool for running `lua-language-server` in check mode for type-checking.
    lualscheck-src = {
      url = "github:9999years/lualscheck";
      flake = false;
    };

    # Neovim Lua API type stubs.
    neodev-src = {
      url = "github:folke/neodev.nvim";
      flake = false;
    };

    # Lua code coverage.
    luacov-src = {
      url = "github:lunarmodules/luacov";
      flake = false;
    };
    cluacov-src = {
      url = "github:mpeterv/cluacov";
      flake = false;
    };
    luacov-reporter-lcov-src = {
      url = "github:daurnimator/luacov-reporter-lcov";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
  };

  outputs = inputs @ {
    self,
    mini-nvim,
    nixpkgs,
    ...
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system:
        function (import nixpkgs {
          inherit system;
          overlays = [
            (import ./nix/overlay.nix)
          ];
        }));
  in {
    checks = forAllSystems (
      pkgs: self.packages.${pkgs.system}.checks
    );

    packages = forAllSystems (pkgs: let
      localPkgs = pkgs.callPackage ./nix/mkPackages.nix {
        inherit inputs;
      };
    in {
      pkgs = localPkgs;
    });

    devShells = forAllSystems (pkgs: {
      default = self.packages.${pkgs.system}.pkgs.shell;
    });
  };
}
