{
  config,
  fenix,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages =
    [
      (fenix.packages.${pkgs.system}.complete.withComponents [
        "cargo"
        "clippy"
        "rust-src"
        "rustc"
        "rustfmt"
      ])

      fenix.packages.${pkgs.system}.rust-analyzer

      pkgs.cargo-deny
      pkgs.cargo-expand
      pkgs.cargo-nextest
      pkgs.cargo-watch
      pkgs.cargo-workspaces
    ]
    ++ lib.optionals config.isLinux [
      pkgs.cargo-llvm-cov
    ];
}
