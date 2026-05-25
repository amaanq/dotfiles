{
  circus,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.services.circusAgentClient;
in
{
  imports = [ circus.nixosModules.circus-agent ];

  options.services.circusAgentClient = {
    enable = mkEnableOption "this host as a circus build agent";

    maxJobs = mkOption {
      type = types.ints.positive;
      default = config.builderMaxJobs;
      defaultText = "builderMaxJobs";
      description = "Concurrent builds this agent accepts.";
    };

    supportedFeatures = mkOption {
      type = types.listOf types.str;
      default = config.nix.settings.system-features;
      defaultText = "config.nix.settings.system-features";
      description = "nix system features advertised to the runner.";
    };
  };

  config = mkIf cfg.enable {
    secrets = {
      circusAgentToken = {
        rekeyFile = ./circus-agent-token.age;
        owner = "circus-agent";
      };

      circusAgentClientKey = {
        rekeyFile = ./circus-agent-client-key.age;
        owner = "circus-agent";
      };
    };

    services.circus-agent = enabled {
      package = circus.packages.${system}.circus-agent;
      authTokenFile = config.secrets.circusAgentToken.path;

      settings.agent = {
        name = config.networking.hostName;
        runner_url = "circus+tls://circus-agent-rpc.manic.systems:8443";
        systems = [ system ];
        supported_features = cfg.supportedFeatures;
        max_jobs = cfg.maxJobs;
        tls = {
          ca_file = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          cert_file = ./circus-agent-client.crt;
          key_file = config.secrets.circusAgentClientKey.path;
        };
      };
    };
  };
}
