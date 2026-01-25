{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce;

  nushellWrapped =
    (pkgs.writeShellScriptBin "nu" ''
      exec ${pkgs.nushell}/bin/nu --config /etc/nushell/config.nu "$@"
    '').overrideAttrs
      { passthru.shellPath = "/bin/nu"; };
in
{
  environment.shellAliases = {
    ls = mkForce null;
    l = mkForce null;
  };

  environment.systemPackages = [ nushellWrapped ];

  users.defaultUserShell = nushellWrapped;
}
