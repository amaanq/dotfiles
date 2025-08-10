{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  virtualisation = {
    waydroid = enabled;
  };
}
