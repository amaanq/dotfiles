{ lib, pkgs, ... }:
let
  inherit (lib) disabled enabled;
in
{
  documentation = {
    doc = disabled;
    dev = enabled;
    info = disabled;
    man = enabled;
  };

  environment.systemPackages = [
    pkgs.man-pages
    pkgs.man-pages-posix
  ];
}
