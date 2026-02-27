{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = lib.theme;
in
{
  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    packages = [ pkgs.terminus_font ];
    # Rose Pine TTY colors
    colors = [
      colors.base00 # black
      colors.base08 # red (love)
      colors.base0B # green (pine)
      colors.base09 # yellow (gold)
      colors.base0D # blue (iris)
      colors.base0E # magenta (iris)
      colors.base0C # cyan (foam)
      colors.base05 # white (text)
      colors.base03 # bright black (muted)
      colors.base08 # bright red
      colors.base0B # bright green
      colors.base09 # bright yellow
      colors.base0D # bright blue
      colors.base0E # bright magenta
      colors.base0C # bright cyan
      colors.base07 # bright white
    ];
  };

  fonts.packages = [
    config.theme.font.sans.package
    pkgs.material-symbols
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-lgc-plus
    pkgs.noto-fonts-color-emoji
    pkgs.nerd-fonts.symbols-only
  ];
}
