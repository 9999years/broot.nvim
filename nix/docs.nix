{
  stdenv,
  vimhelp,
}:
stdenv.mkDerivation {
  name = "broot.nvim-docs";

  src = ../.;

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    vimhelp
  ];

  installPhase = ''
    mkdir -p "$out"
    vimhelp doc/ --out-dir "$out"
    cp "$out/broot.nvim.txt.html" "$out/index.html"
  '';
}
