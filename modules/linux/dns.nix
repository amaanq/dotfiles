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
        version = "0.26.0-alpha.1";
        src = pkgs.fetchFromGitHub {
          owner = "hickory-dns";
          repo = "hickory-dns";
          rev = "8065bacde2ed02dfa7fd5019b50882bdb8a88475";
          hash = "sha256-7aO4p4Kh0B18jIaB6R1UkZHWkGMbdhwos5CsEOymyxQ=";
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

      zones = [
        # UDP for Headscale MagicDNS zone
        {
          zone = "cirque.amaanq.com";
          zone_type = "External";
          stores = {
            type = "forward";
            name_servers = singleton {
              ip = "100.100.100.100";
              trust_negative_responses = true;
              connections = singleton {
                protocol.type = "udp";
              };
            };
          };
        }
        # DoH/DoQ for anything else
        {
          zone = ".";
          zone_type = "External";
          stores = {
            type = "forward";
            name_servers = [
              {
                ip = "2a07:a8c0::";
                trust_negative_responses = true;
                connections = [
                  {
                    protocol = {
                      server_name = "dns.nextdns.io";
                      path = "/9b2c13/${hostname}";
                      type = "h3";
                    };
                  }
                  {
                    protocol = {
                      server_name = "dns.nextdns.io";
                      path = "/9b2c13/${hostname}";
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
              }
              {
                ip = "2a07:a8c1::";
                trust_negative_responses = true;
                connections = [
                  {
                    protocol = {
                      server_name = "dns.nextdns.io";
                      path = "/9b2c13/${hostname}";
                      type = "h3";
                    };
                  }
                  {
                    protocol = {
                      server_name = "dns.nextdns.io";
                      path = "/9b2c13/${hostname}";
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
              }
            ];
          };
        }
      ];
    };
  };

  networking.nameservers = [ "127.0.0.53" ];

  networking.search = [ "cirque.amaanq.com" ];

  # Prevent DHCP from overriding DNS settings, because Verizon's DNS is garbage and hangs my matrix homeserver.
  # dhcpcd
  networking.dhcpcd.extraConfig = "nohook resolv.conf";
  # systemd-networkd
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.UseDNS = false;
  systemd.network.networks."99-ethernet-default-dhcp".dhcpV6Config.UseDNS = false;
  systemd.network.networks."99-ethernet-default-dhcp".ipv6AcceptRAConfig.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".dhcpV4Config.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".dhcpV6Config.UseDNS = false;
  systemd.network.networks."99-wireless-client-dhcp".ipv6AcceptRAConfig.UseDNS = false;
}
