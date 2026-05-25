{
  circus,
  config,
  lib,
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

    cores = mkOption {
      type = types.ints.unsigned;
      default = 0;
      description = "Per-build nix cores cap. 0 keeps the host default.";
    };
  };

  config = mkIf cfg.enable {
    secrets.circusAgentToken = {
      rekeyFile = ./circus-agent-token.age;
      owner = "circus-agent";
    };

    services.circus-agent = enabled {
      authTokenFile = config.secrets.circusAgentToken.path;

      settings.agent = {
        name = config.networking.hostName;
        runner_url = "circus+tls://circus-agent-rpc.manic.systems:8443";
        supported_features = cfg.supportedFeatures;
        max_jobs = cfg.maxJobs;
        inherit (cfg) cores;
      };
    };
  };
}
