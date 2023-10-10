{
  rustPlatform,
  lualscheck-src,
}:
rustPlatform.buildRustPackage {
  name = "lualscheck";
  version = "1.0.0";

  src = lualscheck-src;

  cargoHash = "sha256-LgYMCnNUBb+L+oGHnrZ6fdUDZ7rZ9NA1VdSkNIRz3mk=";
}
