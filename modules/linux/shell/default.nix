{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  wrappers.nushell.executables.nu.environment.LD_PRELOAD.value =
    "${pkgs.mimalloc}/lib/libmimalloc.so";

  users.defaultUserShell = config.wrappers.nushell.finalPackage;

  environment.shellAliases = {
    ls = lib.mkForce null;
    l = lib.mkForce null;
  };

  programs.inshellah = enabled;
}
