{
  config,
  lib,
  pkgs,
  ...
}:
let
  nushellPatched = pkgs.nushell.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./fix-eprintln-double-panic.patch
      ./fix-eprintln-report-error.patch
      ./fix-ls-control-chars.patch
    ];
  });
in
{
  wrappers.nushell = {
    basePackage = nushellPatched;
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
