{ lib, ... }:
let
  httpPort = stringToPort "blocky";
  dnsPort = 5053;
  inherit (lib) enabled stringToPort;
in
{
  networking.firewall = {
    allowedTCPPorts = [ dnsPort ];
    allowedUDPPorts = [ dnsPort ];
  };

  services.blocky = enabled {
    settings = {
      ports = {
        dns = dnsPort;
      };

      upstreams = {
        groups = {
          default = [
            "1.1.1.1"
            "1.0.0.1"
            "8.8.8.8"
            "8.8.4.4"
          ];
        };
      };

      blocking = {
        blackLists = {
          ads = [
            "https://someonewhocares.org/hosts/zero/hosts"
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "https://mirror1.malwaredomains.com/files/justdomains"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
          ];
          special = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
          ];
        };

        whiteLists = {
          ads = [
            "whitelist.txt"
          ];
        };

        clientGroupsBlock = {
          default = [
            "ads"
            "special"
          ];
        };
      };

      caching = {
        minTime = "5m";
        maxTime = "30m";
        maxItemsCount = 0;
        prefetching = true;
        prefetchExpires = "2h";
        prefetchThreshold = 5;
        prefetchMaxItemsCount = 0;
      };

      queryLog = {
        type = "console";
      };

      prometheus = {
        enable = true;
        path = "/metrics";
      };

      httpPort = httpPort;
    };
  };
}
