{
  self,
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
  goAwayPort = stringToPort "go-away:forgejo";

  goAwayPolicy = import (self + /modules/go-away/policy.nix);

  forgejo' = (pkgs.callPackage (self + /packages/forgejo.nix) { }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./discord-webhook.patch
      ./custom-pages.patch
      ./custom-ci-icons.patch
    ];
  });
in
{
  imports = [ (self + /modules/go-away) ];

  services.go-away.instances.forgejo = enabled {
    bindAddress = "[::1]:${toString goAwayPort}";
    metricsAddress = "[::1]:9099";
    backends.${domain} = "http://[::1]:${toString port}";
    challengeTemplate = "forgejo";
    challengeTemplateTheme = "forgejo-auto";
    policy = goAwayPolicy.mkPolicy {
      extraChallenges = [ "http-cookie-check" ];
      extraChallengeDefs = {
        http-cookie-check = {
          runtime = "http";
          parameters = {
            http-url = "http://[::1]:${toString port}/user/stopwatches";
            http-method = "GET";
            http-cookie = "i_like_gitea";
            http-code = 200;
            verify-probability = 0.1;
          };
        };
      };
      wellKnownExtras = [
        ''path == "/app-ads.txt" || path == "/ads.txt"''
        ''path == "/crossdomain.xml"''
      ];
      staticAssets = [
        ''path == "/apple-touch-icon.png"''
        ''path == "/apple-touch-icon-precomposed.png"''
        ''path.startsWith("/assets/")''
        ''path.startsWith("/repo-avatars/")''
        ''path.startsWith("/avatars/")''
        ''path.startsWith("/avatar/")''
        ''path.startsWith("/user/avatar/")''
        ''path.startsWith("/attachments/")''
      ];
      extraConditions = {
        is-git-path = [
          ''path.matches("^/[^/]+/[^/]+/(git-upload-pack|git-receive-pack|HEAD|info/refs|info/lfs|objects)")''
        ];
        is-git-ua = [
          ''userAgent.startsWith("git/") || userAgent.contains("libgit")''
          ''userAgent.startsWith("go-git")''
          ''userAgent.startsWith("JGit/") || userAgent.startsWith("JGit-")''
          ''userAgent.startsWith("GoModuleMirror/")''
          ''userAgent.startsWith("Go-http-client/") && "go-get" in query && query["go-get"] == "1"''
          ''"Git-Protocol" in headers && headers["Git-Protocol"] == "version=2"''
        ];
        is-heavy-resource = [
          ''path.startsWith("/explore/")''
          ''path.matches("^/[^/]+/[^/]+/src/commit/")''
          ''path.matches("^/[^/]+/[^/]+/compare/")''
          ''path.matches("^/[^/]+/[^/]+/commits/commit/")''
          ''path.matches("^/[^/]+/[^/]+/blame/")''
          ''path.matches("^/[^/]+/[^/]+/search/")''
          ''path.matches("^/[^/]+/[^/]+/find/")''
          ''path.matches("^/[^/]+/[^/]+/activity")''
          ''path.matches("^/[^/]+/[^/]+/graph$")''
          ''"q" in query && query.q != ""''
          ''path.matches("^/[^/]+$") && "tab" in query && query.tab == "activity"''
        ];
      };
      serviceRules = [
        {
          name = "always-pow-challenge";
          conditions = [
            ''path.startsWith("/user/sign_up")''
            ''path.startsWith("/user/login") || path.startsWith("/user/oauth2/")''
            ''path.startsWith("/user/activate")''
            ''path == "/repo/create" || path == "/repo/migrate" || path == "/org/create"''
            ''path == "/user/settings" || path.startsWith("/user/settings/hooks/")''
            ''path.matches("^/[^/]+/[^/]+/issues/new")''
            ''path.matches("^/[^/]+/[^/]+/archive/.*\\.(bundle|zip|tar\\.gz)") && ($is-generic-browser)''
          ];
          action = "challenge";
          settings.challenges = [ "js-refresh" ];
        }
        {
          name = "allow-git-operations";
          conditions = [
            "($is-git-path)"
            ''path.matches("^/[^/]+/[^/]+\\.git")''
            ''path.matches("^/[^/]+/[^/]+/") && ($is-git-ua)''
          ];
          action = "pass";
        }
        {
          name = "sitemap";
          conditions = [
            ''path == "/sitemap.xml" || path.matches("^/explore/(users|repos)/sitemap-[0-9]+\\.xml$")''
          ];
          action = "pass";
        }
        {
          name = "api-call";
          conditions = [
            ''path.startsWith("/api/v1/") || path.startsWith("/api/forgejo/v1/")''
            ''path.startsWith("/login/oauth/")''
            ''path.startsWith("/captcha/")''
            ''path.startsWith("/metrics/")''
            ''path == "/-/markup"''
            ''path == "/user/events"''
            ''path == "/ssh_info"''
            ''path == "/api/healthz"''
            ''path.startsWith("/api/actions/") || path.startsWith("/api/actions_pipeline/")''
            ''path.matches("^/[^/]+\\.keys$")''
            ''path.matches("^/[^/]+\\.gpg")''
            ''path.startsWith("/api/packages/") || path == "/api/packages"''
            ''path.startsWith("/v2/") || path == "/v2"''
            ''path.endsWith("/branches/list") || path.endsWith("/tags/list")''
          ];
          action = "pass";
        }
        {
          name = "preview-fetchers";
          conditions = [
            ''path.endsWith("/-/summary-card") || path.matches("^/[^/]+/[^/]+/releases/summary-card/[^/]+$")''
          ];
          action = "pass";
        }
        {
          name = "embed-bots";
          conditions = [
            ''userAgent.contains("Discordbot/") || userAgent.contains("Slackbot") || userAgent.contains("TelegramBot") || userAgent.contains("WhatsApp")''
          ];
          action = "pass";
        }
        {
          name = "homesite";
          conditions = [
            ''path == "/"''
            ''(path.matches("^/[^/]+/[^/]+/?$") || path.matches("^/[^/]+/[^/]+/badges/") || path.matches("^/[^/]+/[^/]+/(issues|pulls)/[0-9]+$") || (path.matches("^/[^/]+/?$") && size(query) == 0)) && !path.matches("(?i)^/(api|metrics|v2|assets|attachments|avatar|avatars|repo-avatars|captcha|login|org|repo|user|admin|devtest|explore|issues|pulls|milestones|notifications|ghost)(/|$)")''
          ];
          action = "pass";
        }
        {
          name = "heavy-operations";
          conditions = [ "($is-heavy-resource)" ];
          action = "none";
          children = [
            { name = "0"; action = "check"; settings.challenges = [ "preload-link" "header-refresh" "js-refresh" "http-cookie-check" ]; }
            { name = "1"; action = "check"; settings.challenges = [ "resource-load" "js-refresh" "http-cookie-check" ]; }
          ];
        }
        {
          name = "source-download";
          conditions = [
            ''path.matches("^/[^/]+/[^/]+/raw/branch/")''
            ''path.matches("^/[^/]+/[^/]+/archive/")''
            ''path.matches("^/[^/]+/[^/]+/releases/download/")''
            ''path.matches("^/[^/]+/[^/]+/media/") && ($is-generic-browser)''
          ];
          action = "pass";
        }
      ];
    };
  };

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

  services.openssh.settings.AcceptEnv = mkForce [
    "SHELLS"
    "COLOTERM"
    "GIT_PROTOCOL"
  ];

  services.forgejo = enabled {
    lfs = enabled;
    customDir = "/etc/forgejo";

    package = forgejo';
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

      # Route traffic through go-away for bot protection
      locations."/" = {
        proxyPass = "http://[::1]:${toString goAwayPort}";
        extraConfig = /* nginx */ ''
          client_max_body_size 100M;
        '';
      };

      # Metrics bypass go-away (already restricted to localhost)
      locations."/metrics" = {
        proxyPass = "http://[::1]:${toString port}/metrics";
        extraConfig = ''
          allow ::1;
          deny all;
        '';
      };
    };
}
