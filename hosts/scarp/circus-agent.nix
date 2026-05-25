{
  circus,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  imports = [ circus.nixosModules.circus-agent ];

  secrets.circusAgentToken = {
    rekeyFile = ./circus-agent-token.age;
    owner = "circus-agent";
  };

  secrets.circusAgentClientKey = {
    rekeyFile = ./circus-agent-client-key.age;
    owner = "circus-agent";
  };

  services.circus-agent = enabled {
    package = circus.packages.${system}.circus-agent;
    authTokenFile = config.secrets.circusAgentToken.path;

    settings.agent = {
      name = "scarp";
      runner_url = "circus+tls://circus-agent-rpc.manic.systems:8443";
      systems = [ "x86_64-linux" ];
      supported_features = config.nix.settings.system-features;
      max_jobs = config.builderMaxJobs / 2;
      tls = {
        ca_file = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        cert_file = ./circus-agent-client.crt;
        key_file = config.secrets.circusAgentClientKey.path;
      };
    };
  };
}
