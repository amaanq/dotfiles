{ lib, ... }:
let
  inherit (lib) enabled mkBefore stringToPort;

  port = stringToPort "ncro";
in
{
  # ncro (Nix Cache Route Optimizer) races our binary caches by latency and
  # proxies substitution through a local HTTP endpoint, streaming NARs from
  # whichever upstream answers fastest.
  services.ncro = enabled {
    addUpstreamPublicKeys = true;

    settings = {
      server = {
        listen = "127.0.0.1:${toString port}";
        cache_priority = 1;
      };

      logging.level = "warn";

      upstreams = [
        {
          url = "https://cache.amaanq.com";
          priority = 10;
          public_key = "cache.amaanq.com:H0iXsEEFsvUNtWb5v9V8Kss+L4F/tnXwDHXcY+xbmKk=";
        }
        {
          url = "https://cache.manic.systems";
          priority = 20;
          public_key = "cache.manic.systems-1:s6OZanN8Us8vRi0jVivP3qlMn0cYHBjBALKrNe5nH8s=";
        }
        {
          url = "https://cache.garnix.io";
          priority = 20;
          public_key = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
        }
        {
          url = "https://nix-community.cachix.org";
          priority = 20;
          public_key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
        }
        {
          url = "https://cache.nixos.org";
          priority = 30;
          public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        }
      ];
    };
  };

  nix.settings.substituters = mkBefore [ "http://127.0.0.1:${toString port}" ];
}
