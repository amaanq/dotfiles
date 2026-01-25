{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  users.defaultUserShell = pkgs.nushell;

  environment.shellAliases = {
    ls = mkForce null;
    l = mkForce null;
  };
}
