{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  unfree.allowedNames = [
    "steam"
    "steam-unwrapped"
  ];

  programs.gamemode = enabled;
  programs.steam = enabled;

  # Steam uses 32-bit drivers for some unholy fucking reason.
  hardware.graphics.enable32Bit = true;
  environment.systemPackages = [
    pkgs.mangohud
    pkgs.r2modman
  ];
}
