{
  self,
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
    mapAttrs'
    nameValuePair
    filterAttrs
    attrNames
    concatMapStringsSep
    concatStringsSep
    optional
    literalExpression
    ;

  cfg = config.services.go-away;
  yamlFormat = pkgs.formats.yaml { };

  instanceModule = {
    options = {
      enable = mkEnableOption "this go-away instance";

      package = mkOption {
        type = types.package;
        default = cfg.package;
        defaultText = literalExpression "config.services.go-away.package";
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
        description = "Address to expose Prometheus metrics on.";
      };

      backends = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Map of hostnames to backend URLs.";
      };

      challengeTemplate = mkOption {
        type = types.str;
        default = "anubis";
        description = "Challenge page template name (embedded) to use.";
      };

      challengeTemplateFile = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "Custom challenge template file (overrides challengeTemplate).";
      };

      challengeTemplateTheme = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Theme for the challenge template.";
      };

      policy = mkOption {
        inherit (yamlFormat) type;
        default = { };
        description = "Policy as a Nix attrset — generated to YAML at build time.";
      };

      settings = mkOption {
        inherit (yamlFormat) type;
        default = { };
        description = "Additional settings for config.yml";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra command line arguments.";
      };
    };
  };

  enabledInstances = filterAttrs (_: i: i.enable) cfg.instances;
in
{
  options.services.go-away = {
    package = mkOption {
      type = types.package;
      default = pkgs.callPackage (self + /packages/go-away.nix) { };
      defaultText = literalExpression "pkgs.callPackage (self + /packages/go-away.nix) { }";
      description = "Default go-away package for all instances.";
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

    instances = mkOption {
      type = types.attrsOf (types.submodule instanceModule);
      default = { };
      description = "Named go-away instances.";
    };
  };

  config = mkIf (enabledInstances != { }) {
    users.users.${cfg.user} = {
      inherit (cfg) group;
      isSystemUser = true;
      description = "go-away service user";
    };

    users.groups.${cfg.group} = { };

    systemd.services = mapAttrs' (
      name: icfg:
      let
        configFile = yamlFormat.generate "go-away-${name}.yml" icfg.settings;
        policyFile = yamlFormat.generate "go-away-${name}-policy.yml" icfg.policy;
        backendArgs = concatMapStringsSep " " (host: "--backend ${host}=${icfg.backends.${host}}") (
          attrNames icfg.backends
        );
        hasPolicy = icfg.policy != { };
      in
      nameValuePair "go-away-${name}" {
        description = "go-away bot protection (${name})";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          ExecStart = concatStringsSep " " (
            [
              "${icfg.package}/bin/go-away"
              "--bind ${icfg.bindAddress}"
              "--config ${configFile}"
            ]
            ++ optional hasPolicy "--policy ${policyFile}"
            ++ optional (icfg.metricsAddress != null) "--metrics-bind ${icfg.metricsAddress}"
            ++ [
              "--challenge-template ${
                if icfg.challengeTemplateFile != null then icfg.challengeTemplateFile else icfg.challengeTemplate
              }"
            ]
            ++ optional (
              icfg.challengeTemplateTheme != null
            ) "--challenge-template-theme ${icfg.challengeTemplateTheme}"
            ++ [ backendArgs ]
            ++ icfg.extraArgs
          );
          Restart = "on-failure";
          RestartSec = "5s";

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
      }
    ) enabledInstances;
  };
}
