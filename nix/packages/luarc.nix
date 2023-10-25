{
  coreutils,
  writeTextFile,
  inputs,
}: let
  luarc =
    (writeTextFile {
      name = ".luarc.json";
      text = builtins.toJSON {
        "workspace.library" = [
          "./lua"
          "${inputs.neodev-src}/types/stable"
          "\${3rd}/luv/library"
          "\${3rd}/luassert/library"
        ];
      };
    })
    .overrideAttrs {
      passthru.link-to-cwd = ''
        ${coreutils}/bin/ln --force --symbolic ${luarc} .luarc.json
      '';
    };
in
  luarc
