{
  config,
  lib,
  pkgs,
  ...
}:
{
  wrappers.nushell = {
    basePackage = pkgs.nushell;
    systemWide = true;
    passthru.shellPath = "/bin/nu";
    executables.nu.args.prefix = [
      "--config"
      "/etc/nushell/config.nu"
    ];
  };

  users.defaultUserShell = config.wrappers.nushell.finalPackage;

  environment.shellAliases = {
    ls = lib.mkForce null;
    l = lib.mkForce null;
  };
}
