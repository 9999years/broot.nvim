{
  writeShellApplication,
  applyPatches,
  neovim,
  python3,
  vimhelp-src,
}: let
  src = applyPatches {
    name = "vimhelp";
    src = vimhelp-src;
    patches = [./patches/vimhelp.diff];
  };
in
  writeShellApplication {
    name = "vimhelp";

    runtimeInputs = [
      (python3.withPackages (pyPkgs: [
        pyPkgs.flask
      ]))
    ];

    text = ''
      inDir="$1"
      shift
      tmpdir=$(mktemp -d)
      cp -r ${neovim}/share/nvim/runtime/doc/* "$tmpdir/"
      cp -r "$inDir"/* "$tmpdir/"
      python3 ${src}/scripts/h2h.py \
        --project neovim \
        --in-dir "$tmpdir/" \
        "$@"
    '';
  }
