{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled mkForce;
in
{
  environment.etc."forgejo/templates/home.tmpl" = {
    source = ./forgejo/home.tmpl;
  };

  services.openssh.settings.AcceptEnv = mkForce "SHELLS COLOTERM GIT_PROTOCOL";

  services.forgejo = enabled {
    lfs = enabled;
    customDir = "/etc/forgejo";

    package = pkgs.forgejo;
    database = {
      socket = "/run/postgresql";
      type = "postgres";
    };

    settings = {
      DEFAULT = {
        APP_NAME = "Reversed Rooms";
      };
      server = {
        DOMAIN = "git.xeondev.com";
        HTTP_ADDR = "::1";
        HTTP_PORT = 3000;
        ROOT_URL = "https://git.xeondev.com/";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      "ui.meta" = {
        AUTHOR = "Reversed Rooms";
        DESCRIPTION = "A slaveless, non-gatekeeping Git service";
        KEYWORDS = "reversedrooms, Reversed rooms, xeondev, zenless zone zero, ZZZ";
      };
    };
  };

  # Backup configuration
  services.restic.backups = {
    forgejo = {
      user = "root";
      repository = "/backup/forgejo";
      passwordFile = config.secrets.restic-password.path;
      paths = [
        "/var/lib/forgejo"
      ];
      exclude = [
        "/var/lib/forgejo/log"
        "/var/lib/forgejo/data/tmp"
      ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
      initialize = true;
      extraBackupArgs = [
        "--verbose"
        "--exclude-caches"
      ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };
  };

  # Backup directories and secrets
  systemd.tmpfiles.rules = [
    "d /backup 0755 root root -"
    "d /backup/forgejo 0755 root root -"
  ];

  secrets.restic-password.file = ./restic-password.age;
}
