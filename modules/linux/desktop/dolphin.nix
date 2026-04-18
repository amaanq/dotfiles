{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  services.udisks2 = enabled {
    mountOnMedia = true;
  };
  services.upower = enabled;

  systemd.user.services.udiskie = {
    description = "udiskie mount daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --no-tray";
      Restart = "on-failure";
    };
  };

  environment.systemPackages =
    [
      pkgs.ffmpegthumbnailer
      pkgs.udiskie
    ]
    ++ (with pkgs.kdePackages; [
      dolphin
      dolphin-plugins
      ark
      kio
      kio-extras
      kio-fuse
      kservice
      kde-cli-tools
      kimageformats
      ffmpegthumbs
      kdegraphics-thumbnailers
    ]);
}
