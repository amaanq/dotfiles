{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  programs.thunar = enabled {
    plugins = [
      pkgs.xfce.thunar-archive-plugin
      pkgs.xfce.thunar-media-tags-plugin
      pkgs.xfce.thunar-volman
    ];
  };

  services.gvfs = enabled;
  services.udisks2 = enabled {
    mountOnMedia = true;
  };
  services.upower = enabled;

  environment.systemPackages = [
    pkgs.ffmpegthumbnailer
    pkgs.libgsf
    pkgs.kdePackages.ark
    pkgs.xfce.tumbler
    pkgs.gvfs
  ];
}
