{
  mkShell,
  luarc,
  checks,
  inputs,
}:
mkShell {
  MINI_NVIM = "${inputs.mini-nvim}";

  inputsFrom = builtins.attrValues checks;

  shellHook = ''
    ${luarc.link-to-cwd}
  '';
}
