{ lib, pkgs, ... }:
let
  inherit (lib) attrValues enabled;
in
{
  programs.nix-ld = enabled {
    libraries = attrValues {
      inherit (pkgs.stdenv.cc.cc)
        lib
        ;
    };
  };
}
