{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    enabled
    merge
    mkForce
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  unfree.allowedNames = [
    "steam"
    "steam-unwrapped"
  ];

  programs.gamemode = enabled;
  programs.steam = enabled;

  # Nope
  hardware.graphics.enable32Bit = mkForce false;
  environment.systemPackages = [
    pkgs.mangohud
    pkgs.r2modman
  ];
}
