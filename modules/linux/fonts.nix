{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    disabled
    merge
    mkIf
    ;
in
merge
  (mkIf config.isDesktop {
    console = {
      earlySetup = true;
      font = "Lat2-Terminus16";
      packages = [ pkgs.terminus_font ];
    };

    fonts.packages = [
      config.theme.font.sans.package
      pkgs.material-symbols
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-lgc-plus
      pkgs.noto-fonts-emoji
      pkgs.nerd-fonts.symbols-only
    ];
  })
  (
    mkIf config.isServer {
      fonts.fontconfig = disabled;
    }
  )
