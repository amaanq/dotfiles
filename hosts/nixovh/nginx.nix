{
  lib,
  ...
}:
let
  inherit (lib) enabled;
in
{
  services.nginx = enabled {
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "git.xeondev.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://[::1]:3000";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "amaanq12@gmail.com";
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      3000
    ];
  };
}
