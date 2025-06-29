{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    flip
    mkForce
    mkOverride
    mkValue
    ;
in
{
  config.environment.systemPackages = [
    config.services.postgresql.package
  ];

  options.services.postgresql.ensure = mkValue [ ];

  config.services.postgresql = enabled {
    package = pkgs.postgresql_17;

    enableJIT = true;
    enableTCPIP = true; # We override it, but might as well.

    settings.listen_addresses = mkForce "*";
    authentication =
      mkOverride 10 # ini
        ''
          #     DATABASE USER     ADDRESS       AUTHENTICATION
          local all      all                    peer
          host  opengist opengist 127.0.0.1/32  trust
          host  all      all      ::/0          md5
        '';

    ensure = [
      "postgres"
      "root"
    ];

    initdbArgs = [
      "--locale=C"
      "--encoding=UTF8"
    ];
    ensureDatabases = config.services.postgresql.ensure;

    ensureUsers = flip map config.services.postgresql.ensure (name: {
      inherit name;

      ensureDBOwnership = true;

      ensureClauses = {
        login = true;
        superuser = name == "postgres" || name == "root";
      };
    });
  };
}
