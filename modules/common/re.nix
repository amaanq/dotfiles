{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    ;
in
{
  environment.systemPackages = attrValues {
    inherit (pkgs)
      apktool
      binwalk
      frida-tools
      imhex
      radare2
      yara
      ;
  };
}
