{ config, lib, ... }:
let
  inherit (lib)
    genAttrs
    mkConst
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

  config.secrets.resticPassword = { file = ./password.age; };

  config.services.restic.backups = genAttrs config.services.restic.hosts (host: {
    repository = "sftp:backup@${host}:${config.networking.hostName}-backup";
    passwordFile = config.secrets.resticPassword.path;
    initialize = true;

    pruneOpts = [
      "--keep-daily 1"
      "--keep-weekly 1"
      "--keep-monthly 1"
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
