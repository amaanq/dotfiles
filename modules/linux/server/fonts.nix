{ lib, ... }:
let
  inherit (lib) disabled;
in
{
  fonts.fontconfig = disabled;
}
