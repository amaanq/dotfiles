{ config, lib, ... }:
let
  inherit (lib)
    enabled
    merge
    mkIf
    mkForce
    ;
in
merge
<| mkIf config.isDesktop {
  security.rtkit = enabled;

  services.pipewire = enabled {
    alsa = enabled { support32Bit = mkForce false; };
    pulse = enabled;
  };
}
