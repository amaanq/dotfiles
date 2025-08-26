{ config, lib, ... }:
let
  inherit (lib)
    genAttrs
    mkConst
    mkIf
    ;
in
{
  options.services.restic.hosts = mkConst (
    # nunatak backs up to scarp and dykwabi, but scarp doesn't backup to nunatak
    if config.networking.hostName == "nunatak" then
      [
        "scarp"
        "dykwabi"
      ]
    else
      [ ]
  );

  config.secrets.resticPassword = mkIf config.isServer { file = ./password.age; };

  config.services.restic.backups =
    mkIf config.isServer
    <| genAttrs config.services.restic.hosts (host: {
      repository = "sftp:backup@${host}:${config.networking.hostName}-backup";
      passwordFile = config.secrets.resticPassword.path;
      initialize = true;

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      extraBackupArgs = [
        "--verbose"
        "--exclude-caches"
      ];

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    });

}
