{
  self,
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "cache.${domain}";
  port = stringToPort "nix-serve";

  cacheCommon = /* nginx */ ''
    proxy_connect_timeout 2s;

    proxy_cache nix_cache;
    proxy_cache_valid 404 1m;
    proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
    proxy_cache_lock on;
  '';
in
{
  imports = [
    (self + /modules/nginx.nix)
    inputs.harmonia.nixosModules.harmonia
  ];

  secrets.nixServeKey = {
    rekeyFile = ./key.age;
    owner = "root";
  };

  services.harmonia-dev.cache = enabled {
    signKeyPaths = [ config.secrets.nixServeKey.path ];
    settings = {
      bind = "127.0.0.1:${toString port}";
      priority = 30;
      enable_compression = true;
    };
  };

  services.nginx.appendHttpConfig = /* nginx */ ''
    proxy_cache_path /var/cache/nginx/nix
      levels=1:2
      keys_zone=nix_cache:100m
      max_size=100g
      inactive=60d
      use_temp_path=off;
  '';

  services.nginx.upstreams.nix-cache.extraConfig = ''
    server 100.64.0.6:${toString port} fail_timeout=5s;
    server 127.0.0.1:${toString port} backup;
  '';

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://nix-cache";

    locations."= /nix-cache-info".proxyPass = "http://nix-cache";

    locations."~ \\.narinfo$" = {
      proxyPass = "http://nix-cache";
      extraConfig = cacheCommon + ''
        proxy_cache_valid 200 30d;
      '';
    };

    # Keep NARs on the prefix location; they are immutable and may end in .nar.
    locations."^~ /nar/" = {
      proxyPass = "http://nix-cache";
      extraConfig = cacheCommon + ''
        proxy_cache_valid 200 365d;
      '';
    };
  };
}
