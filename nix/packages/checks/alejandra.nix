{
  mkCheck,
  alejandra,
}:
mkCheck {
  name = "alejandra";
  description = ''
    Check Nix code formatting with `alejandra`.
  '';

  nativeCheckInputs = [
    alejandra
  ];

  checkPhase = ''
    alejandra --check .
  '';
}
