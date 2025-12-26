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
    owner = "gitea-runner";
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

  services.openssh.settings.AcceptEnv = mkForce [ "SHELLS" "COLOTERM" "GIT_PROTOCOL" ];

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
    package = pkgs.forgejo-runner;
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
      extraConfig = # nginx
        ''
          ${config.services.plausible.extraNginxConfigFor domain}
        '';

      # Static assets
      locations."~ ^/(assets|avatars|repo-avatars|user/avatar)/.*" = {
        proxyPass = "http://[::1]:${toString port}";
        extraConfig = # nginx
          ''
            limit_req zone=forgejo_static burst=100 nodelay;
            limit_req_status 429;

            limit_conn forgejo_conn 20;
            limit_conn_status 429;

            expires 1h;
            add_header Cache-Control "public, immutable" always;

            ${config.services.nginx.headers}
          '';
      };

      # API and auth
      locations."~ ^/(api/|user/login|api/v1/users/.*/tokens).*" = {
        proxyPass = "http://[::1]:${toString port}";
        extraConfig = /* nginx */ ''
          client_max_body_size 100M;

          limit_req zone=forgejo_api burst=20 nodelay;
          limit_req_status 429;

          limit_conn forgejo_conn 5;
          limit_conn_status 429;
        '';
      };

      # Git
      locations."~ ^/.*/.*\\.git/.*" = {
        proxyPass = "http://[::1]:${toString port}";
        extraConfig = /* nginx */ ''
          client_max_body_size 100M;

          limit_req zone=forgejo_api burst=10 nodelay;
          limit_req_status 429;

          limit_conn forgejo_conn 3;
          limit_conn_status 429;
        '';
      };

      locations."/" = {
        proxyPass = "http://[::1]:${toString port}";
        extraConfig = /* nginx */ ''
          client_max_body_size 100M;

          limit_req zone=forgejo_general burst=30 nodelay;
          limit_req_status 429;

          limit_conn forgejo_conn 10;
          limit_conn_status 429;
        '';
      };

      locations."/metrics" = {
        proxyPass = "http://[::1]:${toString port}/metrics";
        extraConfig = ''
          allow ::1;
          deny all;
        '';
      };
    };
}
