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
    vimhelp = {
      url = "github:c4rlo/vimhelp";
      flake = false;
    };

    # Tool for running `lua-language-server` in check mode for type-checking.
    lualscheck = {
      url = "github:9999years/lualscheck";
      flake = false;
    };

    # Neovim Lua API type stubs.
    neodev = {
      url = "github:folke/neodev.nvim";
      flake = false;
    };

    # Lua code coverage.
    luacov = {
      url = "github:lunarmodules/luacov";
      flake = false;
    };
    cluacov = {
      url = "github:mpeterv/cluacov";
      flake = false;
    };
    luacov-reporter-lcov = {
      url = "github:daurnimator/luacov-reporter-lcov";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
  };

  outputs = {
    self,
    nixpkgs,
    mini-nvim,
    vimhelp,
    lualscheck,
    neodev,
    luacov,
    cluacov,
    luacov-reporter-lcov,
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
      pkgs: let
        mkCheck = pkgs.callPackage ./nix/mkCheck.nix {
          luarc = self.packages.${pkgs.system}.luarc;
        };
        luaPkgs = pkgs.lua5_1.pkgs;
      in {
        # mini.nvim unit tests.
        tests = mkCheck {
          name = "tests";

          nativeCheckInputs = [
            pkgs.neovim
            pkgs.broot
            pkgs.git
          ];

          MINI_NVIM = "${mini-nvim}";

          checkPhase = ''
            git init
            make test
          '';
        };

        luacov = self.checks.${pkgs.system}.tests.override (old: {
          name = "luacov";

          nativeCheckInputs =
            (old.nativeCheckInputs or [])
            ++ [
              self.packages.${pkgs.system}.luacov
              self.packages.${pkgs.system}.cluacov
              pkgs.lcov
            ];

          COVERAGE = true;

          installPhase = ''
            mkdir $out
            cp target/coverage.lcov $out/
            cp target/coverage-summary.txt $out/
            cp --recursive target/coverage-report $out/
          '';
        });

        # Check diagnostics and type annotations with `lua-language-server`.
        luals = mkCheck {
          name = "lua-language-server";

          nativeCheckInputs = [
            self.packages.${pkgs.system}.lualscheck
            pkgs.lua-language-server
          ];

          checkPhase = ''
            lualscheck
          '';
        };

        # Lua code formatting with stylua.
        stylua = mkCheck {
          name = "stylua";

          nativeCheckInputs = [
            pkgs.stylua
          ];

          checkPhase = ''
            stylua --check .
          '';
        };

        # Nix code formatting with alejandra.
        alejandra = mkCheck {
          name = "alejandra";

          nativeCheckInputs = [
            pkgs.alejandra
          ];

          checkPhase = ''
            alejandra --check .
          '';
        };

        luacheck = mkCheck {
          name = "luacheck";

          nativeCheckInputs = [luaPkgs.luacheck];

          checkPhase = ''
            luacheck .
          '';
        };
      }
    );

    packages = forAllSystems (pkgs: {
      vimhelp = pkgs.callPackage ./nix/vimhelp.nix {vimhelp-src = vimhelp;};

      lualscheck = pkgs.callPackage ./nix/lualscheck.nix {lualscheck-src = lualscheck;};

      docs = pkgs.callPackage ./nix/docs.nix {
        vimhelp = self.packages.${pkgs.system}.vimhelp;
      };

      luarc = pkgs.callPackage ./nix/luarc.nix {inherit neodev;};

      luacov = pkgs.callPackage ./nix/luacov.nix {
        inherit luacov;
        luacov-reporter-lcov = self.packages.${pkgs.system}.luacov-reporter-lcov;
      };
      cluacov = pkgs.callPackage ./nix/cluacov.nix {
        inherit cluacov;
        luacov = self.packages.${pkgs.system}.luacov;
      };
      luacov-reporter-lcov = pkgs.callPackage ./nix/luacov-reporter-lcov.nix {
        inherit luacov-reporter-lcov;
      };

      coverage = self.checks.${pkgs.system}.luacov;
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        MINI_NVIM = "${mini-nvim}";

        inputsFrom = builtins.attrValues self.checks.${pkgs.system};

        shellHook = ''
          ${self.packages.${pkgs.system}.luarc.link-to-cwd}
        '';
      };
    });
  };
}
