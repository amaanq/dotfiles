{ lib, ... }:
let
  inherit (lib) enabled;
  port = 2001;
in
{
  services.openssh = enabled {
    ports = [ port ];
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;

      AcceptEnv = [
        "SHELLS"
        "COLORTERM"
      ];
    };
  };
}
