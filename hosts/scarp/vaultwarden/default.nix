{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib)
    enabled
    genAttrs
    const
    merge
    stringToPort
    ;

  fqdn = "vault.${domain}";
  rocketPort = stringToPort "vaultwarden";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  age.secrets."vaultwarden-env" = {
    file = ./env.age;
    owner = "vaultwarden";
    group = "vaultwarden";
  };

  services.vaultwarden = enabled {
    config = {
      DOMAIN = "https://${fqdn}";
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;

      ROCKET_ADDRESS = "::1";
      ROCKET_PORT = rocketPort;

      LOG_LEVEL = "warn";
      EXTENDED_LOGGING = true;
      LOG_FILE = "/var/lib/vaultwarden/vaultwarden.log";

      SHOW_PASSWORD_HINT = false;
      PASSWORD_ITERATIONS = 500000;
    };
    backupDir = "/var/backup/vaultwarden";
    environmentFile = config.age.secrets."vaultwarden-env".path;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations = {
      "/".proxyPass = "http://[::1]:${toString rocketPort}";

      "/notifications/hub" = {
        proxyPass = "http://[::1]:${toString rocketPort}";
        proxyWebsockets = true;
      };

      "/notifications/hub/negotiate" = {
        proxyPass = "http://[::1]:${toString rocketPort}";
      };
    };

    extraConfig = ''
      client_max_body_size 525M;
    '';
  };

  services.restic.backups =
    genAttrs config.services.restic.hosts
    <| const {
      paths = [
        "/var/lib/vaultwarden"
        config.services.vaultwarden.backupDir
      ];
    };
}
