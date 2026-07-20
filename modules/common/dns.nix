{ config, lib, ... }:
let
  inherit (lib) mkConst singleton;
  hostname = config.networking.hostName;
  inherit (config.dns) nextdns;

  mkNextDnsServer = ip: {
    inherit ip;
    trust_negative_responses = true;
    connections = [
      {
        protocol = {
          server_name = "dns.nextdns.io";
          path = "/${nextdns.profile}/${hostname}";
          type = "h3";
        };
      }
      {
        protocol = {
          server_name = "dns.nextdns.io";
          path = "/${nextdns.profile}/${hostname}";
          type = "https";
        };
      }
      {
        protocol = {
          server_name = "${hostname}-${nextdns.profile}.dns.nextdns.io";
          type = "quic";
        };
      }
      {
        protocol = {
          server_name = "${hostname}-${nextdns.profile}.dns.nextdns.io";
          type = "tls";
        };
      }
    ];
  };
in
{
  options.dns.listenAddress = mkConst "127.0.0.53";

  options.dns.hickorySettings = mkConst {
    listen_port = 53;
    listen_addrs_ipv4 = singleton config.dns.listenAddress;
    listen_addrs_ipv6 = singleton "::1";

    zones = [
      # UDP for Headscale MagicDNS zone
      {
        zone = config.dns.tailnetDomain;
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
          name_servers = map mkNextDnsServer nextdns.servers;
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

  # Headscale advertises this suffix and hickory forwards the zone to MagicDNS.
  options.dns.tailnetDomain = mkConst "cirque.amaanq.com";

  options.dns.nextdns = {
    profile = mkConst "9b2c13";

    servers = mkConst [
      "2a07:a8c0::"
      "2a07:a8c1::"
      "45.90.28.0"
      "45.90.30.0"
    ];
  };

  options.dns.servers = mkConst (
    map (ip: "${ip}#${hostname}-${nextdns.profile}.dns.nextdns.io") nextdns.servers
  );

  options.dns.serversFallback = mkConst [
    "1.1.1.1#one.one.one.one"
    "2606:4700:4700::1111#one.one.one.one"

    "1.0.0.1#one.one.one.one"
    "2606:4700:4700::1001#one.one.one.one"

    "8.8.8.8#dns.google"
    "2001:4860:4860::8888#dns.google"

    "8.8.4.4#dns.google"
    "2001:4860:4860::8844#dns.google"
  ];
}
