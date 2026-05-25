{
  self,
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf (config.isDesktop && config.isLinux) {
    secrets.circusAgentCfarmToken = {
      rekeyFile = ./circus-agent-cfarm-token.age;
      owner = "amaanq";
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "cfarm-agent";
        runtimeInputs = [
          pkgs.nushell
          pkgs.openssh
          pkgs.rsync
        ];
        text = ''
          export CFARM_AGENT_TOKEN_FILE=${config.secrets.circusAgentCfarmToken.path}
          exec nu ${self}/modules/common/desktop/slop/cfarm-agent.nu "$@"
        '';
      })
    ];
  };
}
