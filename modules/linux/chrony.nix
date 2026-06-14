{ config, lib, ... }:
let
  inherit (lib) enabled optionalString;
  # These boards have no battery-backed RTC, so they cold-boot at a wildly-wrong
  # year. DNSSEC (checks RRSIG validity windows) and NTS (checks TLS cert
  # validity) both need a roughly-correct clock, and chrony needs DNS to resolve
  # its NTS servers.
  rtcless = config.nixpkgs.hostPlatform.isLoongArch64 or false;
in
{
  # Chrony with NTS for authenticated time sync.
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
    ''
    + optionalString rtcless ''
      server 162.159.200.123 iburst
      server 162.159.200.1 iburst
      server 216.239.35.0 iburst
      server 216.239.35.4 iburst
      makestep 1.0 3
    '';
  };
}
