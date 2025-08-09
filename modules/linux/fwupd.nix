{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  services.fwupd = enabled;
}
