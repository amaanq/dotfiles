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
    };
}
