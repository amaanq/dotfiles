{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  home-manager.sharedModules = [
    {
      xdg.mimeApps = enabled {
        defaultApplications = {
          # Browser
          "text/html" = "thorium-browser.desktop";
          "x-scheme-handler/about" = "thorium-browser.desktop";
          "x-scheme-handler/chrome" = "thorium-browser.desktop";
          "x-scheme-handler/http" = "thorium-browser.desktop";
          "x-scheme-handler/https" = "thorium-browser.desktop";
          "x-scheme-handler/unknown" = "thorium-browser.desktop";
          "application/x-extension-htm" = "thorium-browser.desktop";
          "application/x-extension-html" = "thorium-browser.desktop";
          "application/x-extension-shtml" = "thorium-browser.desktop";
          "application/xhtml+xml" = "thorium-browser.desktop";
          "application/x-extension-xhtml" = "thorium-browser.desktop";
          "application/x-extension-xht" = "thorium-browser.desktop";

          "x-scheme-handler/ror2mm" = "r2modman.desktop";
          "x-scheme-handler/tg" = "web-app-Telegram.desktop";
          "x-scheme-handler/tonsite" = "web-app-Telegram.desktop";
          "x-scheme-handler/matrix" = "web-app-Element.desktop";
          "x-scheme-handler/discord" = "vesktop.desktop";

          "x-scheme-handler/mailto" = "userapp-Thunderbird-3NCNA3.desktop";
          "message/rfc822" = "userapp-Thunderbird-3NCNA3.desktop";
          "x-scheme-handler/mid" = "userapp-Thunderbird-3NCNA3.desktop";
          "x-scheme-handler/news" = "userapp-Thunderbird-95BLA3.desktop";
          "x-scheme-handler/snews" = "userapp-Thunderbird-95BLA3.desktop";
          "x-scheme-handler/nntp" = "userapp-Thunderbird-95BLA3.desktop";
          "x-scheme-handler/feed" = "userapp-Thunderbird-YEKOA3.desktop";
          "application/rss+xml" = "userapp-Thunderbird-YEKOA3.desktop";
          "application/x-extension-rss" = "userapp-Thunderbird-YEKOA3.desktop";
          "x-scheme-handler/webcal" = "userapp-Thunderbird-YMTHA3.desktop";
          "text/calendar" = "userapp-Thunderbird-YMTHA3.desktop";
          "application/x-extension-ics" = "userapp-Thunderbird-YMTHA3.desktop";
          "x-scheme-handler/webcals" = "userapp-Thunderbird-YMTHA3.desktop";
        };
      };
    }
  ];
}
