{ lib, pkgs, ... }:
{
  systemd.user.services.radicle-node = {
    description = "Radicle node";
    path = [ pkgs.gitMinimal ];
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "amaanq";
    serviceConfig = {
      Environment = "RAD_HOME=%h/.local/share/radicle";
      ExecStart = "${lib.getExe' pkgs.radicle-node "radicle-node"} --force --log-logger systemd";
      KillMode = "process";
      Restart = "always";
      RestartSec = 3;
    };
  };
}
