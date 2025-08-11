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
    pkgs.gef
    pkgs.imhex
    pkgs.patchelf
    pkgs.pwninit
    pkgs.radare2
    pkgs.yara
  ];
}
