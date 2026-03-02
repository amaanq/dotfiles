{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib)
    enabled
    merge
    mkForce
    stringToPort
    ;

  fqdn = "git.${domain}";
  port = stringToPort "git";
  goAwayPort = stringToPort "go-away:forgejo";

  forgejo' = pkgs.callPackage (self + /packages/forgejo.nix) { };

  goAwayPolicy = import (self + /modules/go-away/policy.nix);
in
{
  networking.firewall.allowedTCPPorts = [ 6767 ];

  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
    (self + /modules/go-away)
  ];

  services.go-away.instances.forgejo = enabled {
    bindAddress = "[::1]:${toString goAwayPort}";
    metricsAddress = "[::]:9099";
    backends = {
      ${fqdn} = "http://[::1]:${toString port}";
    };
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

  secrets.forgejoRunnerToken = {
    file = ./runner.age;
    owner = "gitea-runner";
  };

  services.postgresql.ensure = [ "forgejo" ];

  services.openssh.settings.AcceptEnv = mkForce [
    "SHELLS"
    "COLOTERM"
    "GIT_PROTOCOL"
  ];

  services.forgejo = enabled {
    lfs = enabled;

    database = {
      socket = "/run/postgresql";
      type = "postgres";
    };

    package = forgejo';

    settings =
      let
        description = "amaanq's git instance";
      in
      {
        default.APP_NAME = description;

        attachment.ALLOWED_TYPES = "*/*";

        cache.ENABLED = true;

        # AI scrapers can go to hell (w sphere).
        "cron.archive_cleanup" =
          let
            interval = "4h";
          in
          {
            SCHEDULE = "@every ${interval}";
            OLDER_THAN = interval;
          };

        mailer = {
          ENABLED = true;

          PROTOCOL = "smtps";
          SMTP_ADDR = "mail.amaanq.com";
          USER = "git@${domain}";
        };

        other = {
          SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
          SHOW_FOOTER_VERSION = false;
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

        "repository.upload" = {
          FILE_MAX_SIZE = 100;
          MAX_FILES = 10;
        };

        server = {
          DOMAIN = domain;
          ROOT_URL = "https://${fqdn}/";
          LANDING_PAGE = "/explore";

          HTTP_ADDR = "::1";
          HTTP_PORT = port;

          START_SSH_SERVER = true;
          SSH_LISTEN_HOST = "::";
          SSH_LISTEN_PORT = 6767;
          SSH_PORT = 6767;

          DISABLE_ROUTER_LOG = true;
        };

        service.DISABLE_REGISTRATION = true;

        session = {
          COOKIE_SECURE = true;
          SAME_SITE = "strict";
        };

        "ui.meta" = {
          AUTHOR = description;
          DESCRIPTION = description;
        };
      };
  };

  virtualisation.podman = enabled {
    dockerCompat = true;
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = enabled {
      name = "monolith";
      url = "https://git.xeondev.com";
      tokenFile = config.secrets.forgejoRunnerToken.path;
      labels = [
        "nixos-latest:docker://nixpkgs/nix-flakes:latest"
      ];
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = config.services.plausible.extraNginxConfigFor fqdn;

    # Route traffic through go-away for bot protection
    locations."/" = {
      proxyPass = "http://[::1]:${toString goAwayPort}";
      extraConfig = "client_max_body_size 512M;";
    };
  };
}
