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
    head
    genAttrs
    mkForce
    stringToPort
    ;

  domain = "git.xeondev.com";
  port = stringToPort "git";
in
{
  system.activationScripts.forgejo-assets = ''
    mkdir -p /etc/forgejo
    ${pkgs.age}/bin/age -d -i ${config.secrets.id.path} ${./assets.tar.gz.age} | ${pkgs.gzip}/bin/gzip -d | ${pkgs.gnutar}/bin/tar -xf - -C /etc/forgejo
  '';

  secrets.forgejoRunnerToken = {
    file = ./runner.age;
    owner = "forgejo-runner";
  };

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

    package = pkgs.forgejo.overrideAttrs (old: {
      doCheck = false;
      patches = (old.patches or [ ]) ++ [
        ./discord-webhook.patch
        ./custom-pages.patch
        ./custom-ci-icons.patch
      ];
    });
    database = {
      socket = "/run/postgresql";
      type = "postgres";
    };
    settings = {
      DEFAULT.APP_NAME = "Reversed Rooms";

      attachment.ALLOWED_TYPES = "*/*";

      cache.ENABLED = true;

      # AI scrapers can go to hell.
      "cron.archive_cleanup" =
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
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";

        HTTP_ADDR = "::1";
        HTTP_PORT = port;

        SSH_PORT = head config.services.openssh.ports;

        DISABLE_ROUTER_LOG = true;
      };

      service.DISABLE_REGISTRATION = true;

      session = {
        COOKIE_SECURE = true;
        SAME_SITE = "strict";
      };

      metrics = {
        ENABLED = true;
        ENABLED_ISSUE_BY_LABEL = true;
        ENABLED_ISSUE_BY_REPOSITORY = true;
        TOKEN = "";
      };

      "ui.meta" = {
        AUTHOR = "Reversed Rooms";
        DESCRIPTION = "A slaveless, non-gatekeeping Git service";
        KEYWORDS = "reversedrooms, Reversed rooms, xeondev, zenless zone zero, ZZZ";
      };
    };
  };

  virtualisation.podman = enabled {
    dockerCompat = true;
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-actions-runner;
    instances.nunatak = enabled {
      name = "nunatak";
      url = "https://git.xeondev.com";
      tokenFile = config.secrets.forgejoRunnerToken.path;
      labels = [
        "nixos-arm64:docker://nixpkgs/nix-flakes:latest"
      ];
    };
  };

  services.nginx.virtualHosts.${domain} =
    (removeAttrs config.services.nginx.sslTemplate [ "useACMEHost" ])
    // {
      enableACME = true;
      extraConfig = config.services.plausible.extraNginxConfigFor domain;
      locations."/" = {
        proxyPass = "http://[::1]:${toString port}";
        extraConfig = # nginx
          ''
            client_max_body_size 100M;
          '';
      };
      locations."/metrics" = {
        proxyPass = "http://[::1]:${toString port}/metrics";
        extraConfig = ''
          allow ::1;
          allow 127.0.0.1;
          deny all;
        '';
      };
    };
}
