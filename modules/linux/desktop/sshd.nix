{ lib, ... }:
let
  inherit (lib) enabled;
  port = 2001;
in
{
  services.openssh = enabled {
    ports = [ port ];
    openFirewall = false;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
    };
  };
}
