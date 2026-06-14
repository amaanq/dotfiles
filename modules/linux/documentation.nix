{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) disabled enabled optionals;
in
{
  documentation = {
    doc = disabled;
    dev = enabled;
    info = disabled;
    nixos = disabled; # configuration.nix(5) man page; its options doc walks all of nixpkgs at eval time
    man.enable = config.isDesktop; # This forces perl to be compiled on my powerpc machines
  };

  # See above comment
  environment.systemPackages = optionals config.isDesktop [
    pkgs.man-pages
    pkgs.man-pages-posix
  ];
}
