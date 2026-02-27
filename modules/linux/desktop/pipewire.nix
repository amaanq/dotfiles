{ lib, ... }:
let
  inherit (lib)
    enabled
    mkForce
    ;
in
{
  security.rtkit = enabled;

  services.pipewire = enabled {
    alsa = enabled { support32Bit = mkForce false; };
    pulse = enabled;
  };
}
