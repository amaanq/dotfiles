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

  fqdn = "vault.${domain}";
  rocketPort = stringToPort "vaultwarden";
  websocketPort = stringToPort "vaultwarden-ws";
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

      WEBSOCKET_ENABLED = true;
      WEBSOCKET_ADDRESS = "::";
      WEBSOCKET_PORT = websocketPort;

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
        proxyPass = "http://[::1]:${toString websocketPort}";
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

  systemd.services.vaultwarden-backup = {
    description = "Backup Vaultwarden data";
    serviceConfig = {
      Type = "oneshot";
      User = "vaultwarden";
      ExecStart = ''
        ${lib.getExe pkgs.sqlite} /var/lib/vaultwarden/db.sqlite3 ".backup '/var/backup/vaultwarden/vaultwarden-$(date +%Y%m%d-%H%M%S).sqlite3'"
      '';
    };
  };

  systemd.timers.vaultwarden-backup = {
    description = "Backup Vaultwarden data daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/backup/vaultwarden 0700 vaultwarden vaultwarden -"
  ];
}
