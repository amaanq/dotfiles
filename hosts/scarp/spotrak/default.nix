{
  self,
  config,
  lib,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge;

  fqdn = "spotify.${domain}";
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  secrets.spotrakEnv.rekeyFile = ./env.age;

  services.spotrak = enabled {
    apiEndpoint = "https://${fqdn}";
    spotifyPublic = "a4afb0b1ee7e44af91be1844f0965678";
    environmentFile = config.secrets.spotrakEnv.path;
    settings.TIMEZONE = config.time.timeZone;
    nginx = enabled;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    enableACME = false;
    extraConfig = config.services.plausible.extraNginxConfigFor fqdn;
  };
}
