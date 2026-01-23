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

  secrets.vaultwardenEnv = {
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

      # SMTP
      SMTP_HOST = "mail.${domain}";
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";
      SMTP_FROM = "vault@${domain}";
      SMTP_USERNAME = "contact@${domain}";
    };
    backupDir = "/var/backup/vaultwarden";
    environmentFile = config.secrets.vaultwardenEnv.path;
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
