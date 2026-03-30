{ lib, config, ... }:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib) types;

  cfg = config.services.bulwark;
in
{
  options.services.bulwark = {
    enable = mkEnableOption "Bulwark webmail";

    package = mkOption {
      type = types.package;
      description = "The Bulwark package to use.";
    };

    jmapServerUrl = mkOption {
      type = types.str;
      description = "URL of the JMAP server (e.g. Stalwart).";
      example = "https://mail.example.com";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port to listen on.";
    };

    sessionSecretFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to an environment file containing SESSION_SECRET=<value>.
        Used to encrypt remember-me cookies. If null, remember-me is disabled.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.bulwark = {
      description = "Bulwark Webmail";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        JMAP_SERVER_URL = cfg.jmapServerUrl;
        PORT = toString cfg.port;
        LOG_LEVEL = "debug";
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/bulwark";
        Restart = "on-failure";
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
      }
      // lib.optionalAttrs (cfg.sessionSecretFile != null) {
        EnvironmentFile = [ cfg.sessionSecretFile ];
      };
    };
  };
}
