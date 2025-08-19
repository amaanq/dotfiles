{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
  (mkIf config.isServer {
    unfree.allowedNames = [
      "teamspeak-server"
    ];

    services.teamspeak3 = enabled {
      openFirewall = true;
    };
  })

  (
    mkIf config.isDesktop {
      unfree.allowedNames = [
        "teamspeak6-client"
      ];

      environment.systemPackages = [
        pkgs.teamspeak6-client
      ];
    }
  )
