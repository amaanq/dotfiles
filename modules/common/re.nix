{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
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
