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
  programs.steam = enabled {
    protontricks = enabled;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };

  # Nope
  hardware.graphics.enable32Bit = mkForce false;
  environment.systemPackages = [
    pkgs.mangohud
    pkgs.gale
  ];
}
