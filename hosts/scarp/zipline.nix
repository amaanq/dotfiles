{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "i.${domain}";
  port = stringToPort "zipline";
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  secrets.ziplineSecret.file = ./zipline/secret.age;

  services.postgresql.ensure = [ "zipline" ];

  services.zipline = enabled {
    database.createLocally = false;

    settings = {
      CORE_PORT = port;
      CORE_HOSTNAME = "127.0.0.1";
      DATABASE_URL = "postgresql://zipline@localhost/zipline?host=/run/postgresql";
      DATASOURCE_TYPE = "local";
      DATASOURCE_LOCAL_DIRECTORY = "/var/lib/zipline/uploads";
      FILES_MAX_FILE_SIZE = "10gb";
    };

    environmentFiles = [ config.secrets.ziplineSecret.path ];
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = "client_max_body_size 10G;";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
}
