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
        }));
  in {
    checks = forAllSystems (pkgs: let
      commonArgs = {
        src = ./.;

        dontConfigure = true;
        dontBuild = true;
        doCheck = true;

        installPhase = ''
          touch $out
        '';
      };
    in {
      tests = pkgs.stdenv.mkDerivation (commonArgs
        // {
          name = "broot.nvim-tests";

          nativeBuildInputs = [
            pkgs.neovim
            pkgs.broot
          ];

          MINI_NVIM = "${mini-nvim}";

          checkPhase = ''
            make test
          '';
        });

      stylua = pkgs.stdenv.mkDerivation (commonArgs
        // {
          name = "broot.nvim-stylua";

          nativeBuildInputs = [
            pkgs.stylua
          ];

          checkPhase = ''
            stylua --check .
          '';
        });

      alejandra = pkgs.stdenv.mkDerivation (commonArgs
        // {
          name = "broot.nvim-alejandra";

          nativeBuildInputs = [
            pkgs.alejandra
          ];

          checkPhase = ''
            alejandra --check .
          '';
        });
    });

    packages = forAllSystems (pkgs: {
      vimhelp = pkgs.writeShellApplication {
        name = "vimhelp";

        runtimeInputs = [
          (pkgs.python3.withPackages (pyPkgs: [
            pyPkgs.flask
          ]))
        ];

        text = ''
          inDir="$1"
          shift
          tmpdir=$(mktemp -d)
          cp -r ${pkgs.neovim}/share/nvim/runtime/doc/* "$tmpdir/"
          cp -r "$inDir"/* "$tmpdir/"
          python3 ${vimhelp}/scripts/h2h.py \
            --project neovim \
            --in-dir "$tmpdir/" \
            "$@"
        '';
      };

      docs = pkgs.stdenv.mkDerivation {
        name = "broot.nvim-docs";

        src = ./.;

        dontConfigure = true;
        dontBuild = true;

        nativeBuildInputs = [
          self.packages.${pkgs.system}.vimhelp
        ];

        installPhase = ''
          mkdir -p "$out"
          vimhelp doc/ --out-dir "$out"
        '';
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
