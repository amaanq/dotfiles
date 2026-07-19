{ lib, ... }:
let
  inherit (lib) const flip genAttrs;
in
{
  xdg.mime.defaultApplications =
    flip genAttrs (const "org.qbittorrent.qBittorrent.desktop") [
      "application/x-bittorrent"
      "x-scheme-handler/magnet"
    ]
    // flip genAttrs (const "nvim.desktop") [
      "application/x-shellscript"
      "text/english"
      "text/plain"
      "text/x-c"
      "text/x-c++"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-makefile"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
    ]
    // {
      "x-scheme-handler/ror2mm" = "r2modman.desktop";
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
}
