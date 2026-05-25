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
    executables.nu = {
      args.prefix = [
        "--config"
        "/etc/nushell/config.nu"
      ];
      environment.LD_PRELOAD.value = "${pkgs.mimalloc}/lib/libmimalloc.so";
    };
  };

  users.defaultUserShell = config.wrappers.nushell.finalPackage;

  environment.shellAliases = {
    ls = lib.mkForce null;
    l = lib.mkForce null;
  };
}
