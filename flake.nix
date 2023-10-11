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
            (pkgs.broot.overrideAttrs {
              patches = [
                (pkgs.fetchpatch {
                  url = "https://github.com/Canop/broot/pull/758.diff";
                  hash = "sha256-TwZ6rOR0TVwCD/8hnrWZw4eFj2mybaK+OXzVHE8Gyho=";
                })
              ];
            })
            pkgs.git
          ];

          MINI_NVIM = "${mini-nvim}";

          checkPhase = ''
            git init
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
      vimhelp = let
        src = pkgs.applyPatches {
          name = "vimhelp";
          src = vimhelp;
          patches = [./nix/patches/vimhelp.diff];
        };
      in
        pkgs.writeShellApplication {
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
            python3 ${src}/scripts/h2h.py \
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
          cp "$out/broot.nvim.txt.html" "$out/index.html"
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
