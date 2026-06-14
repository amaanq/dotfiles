{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = lib.optionals config.isDesktop [ pkgs.radicle-node ];
  environment.variables.RAD_HOME = "$XDG_DATA_HOME/radicle";
}
