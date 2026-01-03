{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    literalExpression
    ;

  cfg = config.services.go-away;
  settingsFormat = pkgs.formats.yaml { };
in
{
  options.services.go-away = {
    enable = mkEnableOption "go-away bot protection reverse proxy";

    package = mkOption {
      type = types.package;
      default = pkgs.go-away;
      defaultText = literalExpression "pkgs.go-away";
      description = "The go-away package to use.";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "[::1]:8079";
      description = "Address and port to bind go-away to.";
    };

    metricsAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "[::1]:9099";
      description = "Address to expose Prometheus metrics on.";
    };

    backends = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        "git.example.com" = "http://[::1]:3000";
      };
      description = "Map of hostnames to backend URLs.";
    };

    challengeTemplate = mkOption {
      type = types.str;
      default = "anubis";
      example = "forgejo";
      description = "Challenge page template to use.";
    };

    challengeTemplateTheme = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "forgejo-auto";
      description = "Theme for the challenge template.";
    };

    policyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the policy YAML file.";
    };

    policySnippetsDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the policy snippets directory.";
    };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = { };
      description = "Additional settings for config.yml";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command line arguments.";
    };

    user = mkOption {
      type = types.str;
      default = "go-away";
      description = "User to run go-away as.";
    };

    group = mkOption {
      type = types.str;
      default = "go-away";
      description = "Group to run go-away as.";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      inherit (cfg) group;
      isSystemUser = true;
      description = "go-away service user";
    };

    users.groups.${cfg.group} = { };

    systemd.services.go-away = {
      description = "go-away bot protection reverse proxy";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart =
          let
            configFile = settingsFormat.generate "go-away-config.yml" cfg.settings;
            backendArgs = lib.concatMapStringsSep " " (host: "--backend ${host}=${cfg.backends.${host}}") (
              lib.attrNames cfg.backends
            );
          in
          lib.concatStringsSep " " (
            [
              "${cfg.package}/bin/go-away"
              "--bind ${cfg.bindAddress}"
              "--config ${configFile}"
            ]
            ++ lib.optional (cfg.policyFile != null) "--policy ${cfg.policyFile}"
            ++ lib.optional (cfg.policySnippetsDir != null) "--policy-snippets ${cfg.policySnippetsDir}"
            ++ lib.optional (cfg.metricsAddress != null) "--metrics-bind ${cfg.metricsAddress}"
            ++ lib.optional (cfg.challengeTemplate != null) "--challenge-template ${cfg.challengeTemplate}"
            ++ lib.optional (
              cfg.challengeTemplateTheme != null
            ) "--challenge-template-theme ${cfg.challengeTemplateTheme}"
            ++ [ backendArgs ]
            ++ cfg.extraArgs
          );
        Restart = "on-failure";
        RestartSec = "5s";

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
      };
    };
  };
}
