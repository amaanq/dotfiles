{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) attrValues makeLibraryPath mkIf;
in
{
  environment.variables = {
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";

    LIBRARY_PATH =
      mkIf config.isDarwin
      <| makeLibraryPath
      <| attrValues {
        inherit (pkgs)
          libiconv
          ;
      };
  };

  environment.shellAliases = {
    cb = "cargo build";
    cbr = "cargo build --release";
    cbrd = "cargo build --profile release-dev";
    ci = "cargo install";
    ct = "cargo test";
    cx = "cargo xtask";
  };

  environment.systemPackages = attrValues {
    inherit (pkgs)
      rust-analyzer-nightly

      cargo-deny
      cargo-expand
      cargo-nextest
      cargo-watch

      evcxr

      taplo
      ;

    fenix = pkgs.fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ];
  };
}
