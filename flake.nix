{
  description = "Broot integration for neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    mini-nvim = {
      url = "github:echasnovski/mini.nvim";
      flake = false;
    };
    vimhelp = {
      url = "github:c4rlo/vimhelp";
      flake = false;
    };
    lualscheck = {
      url = "github:9999years/lualscheck";
      flake = false;
    };
    neodev = {
      url = "github:folke/neodev.nvim";
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

          nativeCheckInputs = [pkgs.lua5_1.pkgs.luacheck];

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
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        MINI_NVIM = "${mini-nvim}";

        inputsFrom = builtins.attrValues self.checks.${pkgs.system};
        packages = [
          pkgs.lua5_1.pkgs.luacheck
        ];

        shellHook = ''
          ${self.packages.${pkgs.system}.luarc.link-to-cwd}
        '';
      };
    });
  };
}
