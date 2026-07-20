{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) const flip genAttrs;

  colors = lib.theme.withHashtag;
in
{
  environment.systemPackages = [ (pkgs.mpv.override { scripts = [ pkgs.mpvScripts.autoload ]; }) ];

  xdg.mime.defaultApplications =
    [
      "audio/aac"
      "audio/ac3"
      "audio/flac"
      "audio/mp4"
      "audio/mpeg"
      "audio/ogg"
      "audio/vnd.wave"
      "audio/webm"
      "audio/x-matroska"
      "audio/x-mpegurl"
      "video/mp2t"
      "video/mp4"
      "video/mpeg"
      "video/ogg"
      "video/quicktime"
      "video/vnd.avi"
      "video/webm"
      "video/x-matroska"
      "video/x-ms-wmv"
    ]
    |> flip genAttrs (const "mpv.desktop");

  environment.variables.MPV_HOME = "/etc/mpv";

  environment.etc."mpv/mpv.conf".text = /* ini */ ''
    # Rose Pine OSD theme
    background-color=#000000
    osd-back-color=${colors.base01}
    osd-border-color=${colors.base01}
    osd-color=${colors.base05}
    osd-shadow-color=${colors.base00}
    osd-font=${config.theme.font.sans.name}
    sub-font=${config.theme.font.sans.name}
  '';
}
