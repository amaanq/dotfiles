{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = lib.theme.withHashtag;
in
{
  environment.systemPackages = [ pkgs.mpv ];

  environment.variables.MPV_HOME = "/etc/mpv";

  environment.etc."mpv/mpv.conf".text = ''
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
