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
    head
    merge
    mkForce
    stringToPort
    ;

  fqdn = "git.${domain}";
  port = stringToPort "git";
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  secrets.forgejoRunnerToken = {
    file = ./runner.age;
    owner = "gitea-runner";
  };

  services.postgresql.ensure = [ "forgejo" ];

  services.openssh.settings.AcceptEnv = mkForce "SHELLS COLOTERM GIT_PROTOCOL";

  services.forgejo = enabled {
    lfs = enabled;

    database = {
      socket = "/run/postgresql";
      type = "postgres";
    };

    package = pkgs.forgejo;

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

          SSH_PORT = head config.services.openssh.ports;

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

    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
