{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;
in
{
  environment.systemPackages = [
    pkgs.apktool
    pkgs.binwalk
    pkgs.gef
    pkgs.imhex
    pkgs.patchelf
    pkgs.radare2
    pkgs.rizin
    pkgs.rizinPlugins.rz-ghidra
    pkgs.yara
  ]
  ++ optionals config.isLinux [
    pkgs.pwninit
  ];

  environment.variables = {
    IDAUSR = "$XDG_DATA_HOME/idapro";
    RZ_LIB_PLUGINS = "${pkgs.rizinPlugins.rz-ghidra}/lib/rizin/plugins";
  };
}
