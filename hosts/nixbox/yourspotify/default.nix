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
  ];

  secrets.yourspotifySecret = {
    file = ./secret.age;
    owner = "your_spotify";
  };

  services.prometheus.exporters.mongodb = enabled {
    listenAddress = "[::]";
    uri = "mongodb://localhost:27017";
    collectAll = true;
  };

  services.your_spotify = enabled {
    enableLocalDB = true;

    spotifySecretFile = config.secrets.yourspotifySecret.path;

    settings = {
      API_ENDPOINT = "https://${fqdn}/api";
      CLIENT_ENDPOINT = "https://${fqdn}";
      SPOTIFY_PUBLIC = "a4afb0b1ee7e44af91be1844f0965678";
      PORT = 8080;
    };

  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = config.services.plausible.extraNginxConfigFor fqdn;

    locations = {
      "/api/" = {
        proxyPass = "http://[::1]:${toString config.services.your_spotify.settings.PORT}/";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
      "/" = {
        root = "${config.services.your_spotify.clientPackage}";
        tryFiles = "$uri $uri/ /index.html";
      };
    };
  };
}
