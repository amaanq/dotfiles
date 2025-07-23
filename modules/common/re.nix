{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.apktool
    pkgs.binwalk
    pkgs.imhex
    pkgs.radare2
    pkgs.yara
  ];
}
