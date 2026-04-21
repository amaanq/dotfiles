{ lib, pkgs, ... }:
let
  inherit (lib) enabled;
in
{
  programs.nix-ld = enabled {
    libraries = [
      pkgs.stdenv.cc.cc.lib
    ];
  };
}
