{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "rss.${domain}";
  port = stringToPort "miniflux";
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  secrets.minifluxCredentials.file = ./credentials.age;

  services.postgresql.ensure = [ "miniflux" ];

  services.miniflux = enabled {
    config = {
      LISTEN_ADDR = "127.0.0.1:${toString port}";
      BASE_URL = "https://${fqdn}";
    };
    adminCredentialsFile = config.secrets.minifluxCredentials.path;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}
