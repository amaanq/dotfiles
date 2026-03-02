{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) enabled merge stringToPort;

  fqdn = "teapot.${domain}";
  port = stringToPort "teapot";
  goAwayPort = stringToPort "go-away:teapot";

  goAwayPolicy = import (self + /modules/go-away/policy.nix);
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/go-away)
  ];

  secrets.teapotSessions = {
    file = ./sessions.age;
    mode = "0444";
  };

  services.go-away.instances.teapot = enabled {
    bindAddress = "[::1]:${toString goAwayPort}";
    backends = {
      ${fqdn} = "http://[::1]:${toString port}";
      "nitter.${domain}" = "http://[::1]:${toString port}";
      "tpot.${domain}" = "http://[::1]:${toString port}";
    };
    challengeTemplateFile = pkgs.writeText "challenge-teapot.gohtml"
      (builtins.readFile (self + /modules/go-away/challenge-teapot.gohtml));
    policy = goAwayPolicy.mkPolicy {
      staticAssets = [
        ''path == "/apple-touch-icon.png"''
        ''path.startsWith("/css/")''
        ''path.startsWith("/js/")''
        ''path.startsWith("/fonts/")''
        ''path.startsWith("/pic/")''
        ''path.startsWith("/video/")''
        ''path == "/logo.svg"''
        ''path == "/site.webmanifest"''
        ''path.matches("\\.(png|ico|svg|woff2|css|js)$")''
      ];
      extraConditions = {
        is-heavy-resource = [
          ''"cursor" in query && query.cursor != ""''
          ''path == "/search" && "q" in query''
          ''path.matches("^/[^/]+/status/[0-9]+/(retweets|quotes)$")''
        ];
      };
      serviceRules = [
        {
          name = "rss-feeds";
          conditions = [ ''path.matches("^/[^/]+/rss$")'' ];
          action = "pass";
        }
        {
          name = "oembed";
          conditions = [ ''path == "/oembed"'' ];
          action = "pass";
        }
        {
          name = "embed-bots";
          conditions = [
            ''userAgent.contains("Discordbot/") || userAgent.contains("Slackbot") || userAgent.contains("TelegramBot") || userAgent.contains("WhatsApp")''
            ''userAgent.contains("facebookexternalhit/") || userAgent.contains("Twitterbot/")''
          ];
          action = "pass";
        }
        {
          name = "media-proxy";
          conditions = [
            ''path.startsWith("/pic/")''
            ''path.startsWith("/video/")''
          ];
          action = "pass";
        }
        {
          name = "heavy-operations";
          conditions = [ "($is-heavy-resource)" ];
          action = "none";
          children = [
            { name = "0"; action = "check"; settings.challenges = [ "preload-link" "header-refresh" "js-refresh" ]; }
            { name = "1"; action = "check"; settings.challenges = [ "resource-load" "js-refresh" ]; }
          ];
        }
        {
          name = "homesite";
          conditions = [
            ''path == "/" || path == "/about"''
            ''path.matches("^/[^/]+/?$") && !path.matches("^/(css|js|fonts|pic|video|settings|opensearch|oembed|search)(/|$)")''
            ''path.matches("^/[^/]+/status/[0-9]+$")''
          ];
          action = "challenge";
          settings.challenges = [ "preload-link" "meta-refresh" ];
        }
        {
          name = "settings-page";
          conditions = [ ''path == "/settings"'' ];
          action = "pass";
        }
      ];
    };
  };

  services.teapot = enabled {
    preferences.infiniteScroll = true;
    server = {
      inherit port;
      address = "::1";
      hostname = fqdn;
      https = true;
      title = "teapot";
    };
    config = {
      paidEmoji = "✡️";
      aiEmoji = "🦼";
    };
    cache.listMinutes = 240;
    sessionsFile = config.secrets.teapotSessions.path;
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString goAwayPort}";
  };

  services.nginx.virtualHosts."nitter.${domain}" = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString goAwayPort}";
  };

  services.nginx.virtualHosts."tpot.${domain}" = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString goAwayPort}";
  };
}
