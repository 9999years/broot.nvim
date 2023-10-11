# This overlay patches some packages for our needs. It doesn't provide
# `broot.nvim` as a package.
final: prev: {
  broot = prev.broot.overrideAttrs {
    patches = [
      (final.fetchpatch {
        # Enables the `root_relative_path` option, which makes our tests work
        # locally and in CI.
        url = "https://github.com/Canop/broot/pull/758.diff";
        hash = "sha256-TwZ6rOR0TVwCD/8hnrWZw4eFj2mybaK+OXzVHE8Gyho=";
      })
    ];
  };
}
