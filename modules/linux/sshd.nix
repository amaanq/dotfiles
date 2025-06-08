{ config, lib, ... }:
let
  inherit (lib) enabled merge mkIf;
  port = 2001;
in
merge
<| mkIf config.isServer {
  programs.mosh = enabled {
    openFirewall = true;
  };

  services.openssh = enabled {
    ports = [ port ];
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;

      AcceptEnv = "SHELLS COLORTERM";
    };
  };
}
