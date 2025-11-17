{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled singleton;
  hostname = config.networking.hostName;
in
{
  services.hickory-dns = enabled {
    package =
      let
        version = "0.26.0-unstable-2024-11-03";
        src = pkgs.fetchFromGitHub {
          owner = "hickory-dns";
          repo = "hickory-dns";
          rev = "fb1a21a23eb036d542177534f64b9cb4efafc4f7";
          hash = "sha256-EHUUHyGlc1v6MYsO/BaqaSmwKW/p/w21jlrYddpvaLk=";
        };
      in
      pkgs.hickory-dns.overrideAttrs (old: {
        inherit version src;
        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = "${src}/Cargo.lock";
        };
        cargoBuildFeatures = old.cargoBuildFeatures or [ ] ++ [
          "h3-aws-lc-rs"
          "https-aws-lc-rs"
        ];
      });

    settings = {
      listen_port = 53;
      listen_addrs_ipv4 = singleton "127.0.0.53";
      listen_addrs_ipv6 = singleton "::1";

      zones = singleton {
        zone = ".";
        zone_type = "External";

        stores = {
          type = "forward";
          name_servers = singleton {
            ip = "2a07:a8c0::";
            trust_negative_responses = true;
            connections = [
              {
                protocol = {
                  server_name = "dns.nextdns.io";
                  path = "/${hostname}-9b2c13";
                  type = "h3";
                };
              }
              {
                protocol = {
                  server_name = "dns.nextdns.io";
                  path = "/${hostname}-9b2c13";
                  type = "https";
                };
              }
              {
                protocol = {
                  server_name = "${hostname}-9b2c13.dns.nextdns.io";
                  type = "quic";
                };
              }
              {
                protocol = {
                  server_name = "${hostname}-9b2c13.dns.nextdns.io";
                  type = "tls";
                };
              }
            ];
          };
        };
      };
    };
  };

  # Prevent DHCP from overriding DNS settings, because Verizon's DNS is garbage and hangs my matrix homeserver.
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.UseDNS = false;
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV6Config.UseDNS = false;
  systemd.network.networks."99-ethernet-default-dhcp".ipv6AcceptRAConfig.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".dhcpV4Config.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".dhcpV6Config.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".ipv6AcceptRAConfig.UseDNS = false;
}
