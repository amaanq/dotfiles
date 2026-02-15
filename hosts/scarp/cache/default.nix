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

  fqdn = "cache.${domain}";
  port = stringToPort "nix-serve";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  secrets.nixServeKey = {
    file = ./key.age;
    owner = "root";
  };

  services.nix-serve = enabled {
    package = pkgs.nix-serve-ng;
    secretKeyFile = config.secrets.nixServeKey.path;
    bindAddress = "127.0.0.1";
    port = port;
  };

  services.nginx.upstreams.nix-cache.extraConfig = ''
    server 100.64.0.6:${toString port} fail_timeout=5s;
    server 127.0.0.1:${toString port} backup;
  '';

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://nix-cache";
      extraConfig = "proxy_connect_timeout 2s;";
    };
  };
}
