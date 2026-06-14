{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge stringToPort;
  fqdn = "rad.${config.networking.domain}";
  httpPort = stringToPort "radicle";
  explorer = pkgs.radicle-explorer.withConfig {
    deploymentId = fqdn;
    preferredSeeds = [
      {
        hostname = fqdn;
        port = 443;
        scheme = "https";
      }
    ];
  };
in
{
  services.radicle = enabled {
    privateKey = "/var/lib/radicle-node.key";
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJm+HiUgIX7xiNchqfZ2A3HEbRcSw6uw+b5N4qHVimX";

    node.openFirewall = true;

    settings.node = {
      alias = fqdn;
      connect = [
        "z6MkkDShaMmwCBAsgpW47rGHLyGvTN1R8FNKu5bQKpQJqyKS@radicle.t16t.com:8776"
      ];
      externalAddresses = [ ];
      seedingPolicy = {
        default = "block";
        scope = "all";
      };
    };

    httpd = enabled {
      listenPort = httpPort;
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    root = explorer;

    locations."/".tryFiles = "$uri $uri/ /index.html";

    locations."/api/" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      recommendedProxySettings = true;
    };

    locations."/raw/" = {
      proxyPass = "http://127.0.0.1:${toString httpPort}";
      recommendedProxySettings = true;
    };
  };
}
