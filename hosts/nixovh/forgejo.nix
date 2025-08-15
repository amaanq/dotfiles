{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    const
    enabled
    genAttrs
    mkForce
    ;
in
{
  system.activationScripts.forgejo-assets = ''
    mkdir -p /etc/forgejo
    ${pkgs.age}/bin/age -d -i ${config.secrets.id.path} ${./forgejo-assets.tar.gz.age} | ${pkgs.gzip}/bin/gzip -d | ${pkgs.gnutar}/bin/tar -xf - -C /etc/forgejo
  '';

  services.postgresql.ensure = [ "forgejo" ];

  services.restic.backups =
    genAttrs config.services.restic.hosts
    <| const {
      paths = [
        "/var/lib/forgejo"
      ];
      exclude = [
        "/var/lib/forgejo/log"
        "/var/lib/forgejo/data/tmp"
        "/var/lib/forgejo/data/repo-archive"
      ];
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
      default.APP_NAME = "Reversed Rooms";

      attachment.ALLOWED_TYPES = "*/*";

      cache.ENABLED = true;

      # AI scrapers can go to hell.
      "cron.archive_cleaup" =
        let
          interval = "4h";
        in
        {
          SCHEDULE = "@every ${interval}";
          OLDER_THAN = interval;
        };

      packages.ENABLED = false;

      repository = {
        DEFAULT_BRANCH = "master";
        DEFAULT_MERGE_STYLE = "rebase-merge";
        DEFAULT_REPO_UNITS = "repo.code, repo.issues, repo.pulls";

        DEFAULT_PUSH_CREATE_PRIVATE = false;
        ENABLE_PUSH_CREATE_ORG = true;
        ENABLE_PUSH_CREATE_USER = true;

        DISABLE_STARS = true;
      };

      "repository.signing" = {
        DEFAULT_TRUST_MODEL = "committer";
      };

      "repository.upload" = {
        FILE_MAX_SIZE = 100;
        MAX_FILES = 10;
      };

      security.INSTALL_LOCK = true;

      server = {
        DOMAIN = "git.xeondev.com";
        HTTP_ADDR = "::1";
        HTTP_PORT = 3000;
        ROOT_URL = "https://git.xeondev.com/";
        DISABLE_ROUTER_LOG = true;
      };

      service.DISABLE_REGISTRATION = true;

      session = {
        COOKIE_SECURE = true;
        SAME_SITE = "strict";
      };

      "ui.meta" = {
        AUTHOR = "Reversed Rooms";
        DESCRIPTION = "A slaveless, non-gatekeeping Git service";
        KEYWORDS = "reversedrooms, Reversed rooms, xeondev, zenless zone zero, ZZZ";
      };
    };
  };
}
