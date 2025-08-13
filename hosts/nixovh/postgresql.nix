{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  services.postgresql = enabled {
    package = pkgs.postgresql_17;
    enableTCPIP = true;
    settings.listen_addresses = "*";
    authentication = ''
      local all all peer
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128       trust
    '';
    ensureDatabases = [ "forgejo" ];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };
}
