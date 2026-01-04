{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;
  fqdn = "images.${domain}";
  port = stringToPort "immich";
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  services.postgresql.ensure = [ "immich" ];

  services.immich = enabled {
    host = "::1";
    inherit port;

    settings.server.externalDomain = "https://${fqdn}";

    database = enabled {
      host = "/run/postgresql";
    };
  };

  systemd.services.immich-server = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://[::1]:${toString port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_cookie_path / /;
      '';
    };

    extraConfig = ''
      client_max_body_size 50000M;
    '';
  };
}
