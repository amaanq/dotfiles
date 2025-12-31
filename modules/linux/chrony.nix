{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  # Chrony with NTS (Network Time Security) for authenticated time sync.
  services.chrony = enabled {
    enableNTS = true;
    servers = [
      "time.cloudflare.com"
      "ntppool1.time.nl"
      "nts.netnod.se"
      "ptbtime1.ptb.de"
    ];
    extraConfig = ''
      # Require at least 3 sources to agree before updating time.
      minsources 3
    '';
  };
}
