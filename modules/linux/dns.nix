{
  config,
  lib,
  ...
}:
let
  inherit (lib) enabled singleton;
  hostname = config.networking.hostName;
in
{
  services.hickory-dns = enabled {
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
            options = {
              cache_size = 1024;
              positive_max_ttl = 300;
              negative_max_ttl = 300;
            };
          };
        }
        # DoH/DoQ for anything else
        {
          zone = ".";
          zone_type = "External";
          stores = {
            type = "forward";
            name_servers =
              let
                mkNextDnsServer = ip: {
                  inherit ip;
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
                };
              in
              [
                (mkNextDnsServer "2a07:a8c0::")
                (mkNextDnsServer "2a07:a8c1::")
                # IPv4 fallback
                (mkNextDnsServer "45.90.28.0")
                (mkNextDnsServer "45.90.30.0")
              ];
            options = {
              cache_size = 32768;
              num_concurrent_reqs = 4;
              positive_min_ttl = 60;
              positive_max_ttl = 86400;
              negative_min_ttl = 900;
              negative_max_ttl = 86400;
            };
          };
        }
      ];
    };
  };

  networking.nameservers = [ "127.0.0.53" ];

  networking.search = [ "cirque.amaanq.com" ];

  # Order hickory-dns before nss-lookup.target so resolver-dependent units wait.
  systemd.services.hickory-dns = {
    before = [ "nss-lookup.target" ];
    wants = [ "nss-lookup.target" ];
  };

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
