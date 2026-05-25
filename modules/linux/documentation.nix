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
    man.enable = config.isDesktop; # This forces perl to be compiled on my powerpc machines
  };

  # See above comment
  environment.systemPackages = optionals config.isDesktop [
    pkgs.man-pages
    pkgs.man-pages-posix
  ];
}
