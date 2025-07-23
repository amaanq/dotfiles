{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) makeLibraryPath mkIf;
in
{
  environment.variables = {
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";

    LIBRARY_PATH = mkIf config.isDarwin <| makeLibraryPath <| [ pkgs.libiconv ];
  };

  environment.shellAliases = {
    cb = "cargo build";
    cbr = "cargo build --release";
    cbrd = "cargo build --profile release-dev";
    ci = "cargo install";
    ct = "cargo test";
    cx = "cargo xtask";
  };

  environment.systemPackages = [
    pkgs.rust-analyzer-nightly

    pkgs.cargo-deny
    pkgs.cargo-expand
    pkgs.cargo-nextest
    pkgs.cargo-watch

    pkgs.evcxr

    pkgs.taplo

    (pkgs.fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
  ];
}
