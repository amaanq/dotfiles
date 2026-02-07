{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "headscale.${domain}";
  port = stringToPort "headscale";

  derpMapRaw = pkgs.fetchurl {
    url = "https://controlplane.tailscale.com/derpmap/default";
    sha256 = "sha256-vUDPx6n2KfkpQ3whonBJEEbEgIKfSL/1naxOXBULpF4=";
  };

  derpMap = pkgs.runCommand "derp-yaml" { } ''
    ${pkgs.jq}/bin/jq 'walk(if type == "object" then with_entries(.key |= ascii_downcase) else . end)' ${derpMapRaw} | \
    ${pkgs.yq-go}/bin/yq -P | \
    ${pkgs.gnused}/bin/sed 's/^  "\([0-9]\+\)":/  \1:/' > $out
  '';
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  services.postgresql.ensure = [ "headscale" ];

  services.headscale = enabled {
    address = "[::1]";
    inherit port;

    settings = {
      server_url = "https://${fqdn}";

      dns = {
        magic_dns = true;
        base_domain = "cirque.${domain}";
        nameservers.global = [
          "45.90.28.0"
          "45.90.30.0"
          "2a07:a8c0::"
          "2a07:a8c1::"
        ];
      };

      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
        allocation = "sequential";
      };

      database = {
        type = "postgres";
        postgres = {
          host = "/run/postgresql";
          name = "headscale";
          user = "headscale";
        };
      };

      derp = {
        urls = [ ];
        auto_update_enabled = false;
        paths = [ "${derpMap}" ];
      };

      ephemeral_node_inactivity_timeout = "30m";

      log = {
        format = "text";
        level = "info";
      };
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
    };
  };
}
