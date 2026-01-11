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
      pkgs.thunar-archive-plugin
      pkgs.thunar-media-tags-plugin
      pkgs.thunar-volman
    ];
  };

  services.gvfs = enabled;
  services.udisks2 = enabled {
    mountOnMedia = true;
  };
  services.upower = enabled;

  home-manager.sharedModules = [
    {
      services.udiskie = enabled;
    }
  ];

  environment.systemPackages = [
    pkgs.ffmpegthumbnailer
    pkgs.libgsf
    pkgs.kdePackages.ark
    pkgs.tumbler
    pkgs.gvfs
  ];
}
