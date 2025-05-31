{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  programs.mosh = enabled {
    openFirewall = true;
  };

  services.openssh.enable = true;
}
