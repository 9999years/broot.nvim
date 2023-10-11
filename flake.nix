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
        mkCheck =
          pkgs.callPackage ./nix/mkCheck.nix {};
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
      }
    );

    packages = forAllSystems (pkgs: {
      vimhelp = pkgs.callPackage ./nix/vimhelp.nix {vimhelp-src = vimhelp;};

      docs = pkgs.callPackage ./nix/docs.nix {
        vimhelp = self.packages.${pkgs.system}.vimhelp;
      };
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        MINI_NVIM = "${mini-nvim}";

        inputsFrom = builtins.attrValues self.checks.${pkgs.system};
      };
    });
  };
}
