{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    enabled
    mkForce
    ;

  # Override Steam to unset LD_PRELOAD in the init script
  # This is needed because the init script sources /etc/profile which
  # re-introduces LD_PRELOAD after our wrapper unsets it
  steamWithoutMalloc = pkgs.steam.override {
    extraLibraries = _: [ ];
    extraProfile = ''
      unset LD_PRELOAD
    '';
  };
in
{
  unfree.allowedNames = [
    "steam"
    "steam-unwrapped"
  ];

  programs.gamemode = enabled;
  programs.steam = enabled {
    package = steamWithoutMalloc;
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
