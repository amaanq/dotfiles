{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib)
    enabled
    merge
    stringToPort
    ;

  fqdn = "anki.${domain}";
  port = stringToPort "anki";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  secrets.ankiSyncPassword.rekeyFile = ./anki-password.age;

  services.anki-sync-server = enabled {
    address = "::1";
    inherit port;

    users = [
      {
        username = "amaanq";
        passwordFile = config.secrets.ankiSyncPassword.path;
      }
    ];
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = "client_max_body_size 0;";
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
