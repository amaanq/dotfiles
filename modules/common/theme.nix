{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkValue;
in
{
  options.theme =
    mkValue
    <|
      {
        cornerRadius = 4;
        borderWidth = 2;

        margin = 0;
        padding = 8;

        font.size.normal = 12;
        font.size.big = 16;

        font.sans.name = "DejaVu Sans";
        font.sans.package = pkgs.dejavu_fonts;

        font.mono.name = "TX-02 Book";

        icons.name = "rose-pine";
        icons.package = pkgs.rose-pine-icon-theme;
      };
}
