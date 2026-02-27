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
    CARGO_HOME = "$XDG_DATA_HOME/cargo";
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
}
