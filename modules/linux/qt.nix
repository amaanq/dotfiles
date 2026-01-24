{
  config,
  lib,
  pkgs,
  qtengine,
  ...
}:
let
  inherit (lib) enabled merge mkIf theme;

  # Convert hex digit to decimal
  hexDigit = c: {
    "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4;
    "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
    "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
    "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
  }.${c};

  # Convert 2-char hex to decimal
  hexPairToDec = s:
    hexDigit (builtins.substring 0 1 s) * 16 + hexDigit (builtins.substring 1 1 s);

  # Convert hex color to RGB tuple string "r,g,b"
  hexToRgb = hex:
    let
      r = hexPairToDec (builtins.substring 0 2 hex);
      g = hexPairToDec (builtins.substring 2 2 hex);
      b = hexPairToDec (builtins.substring 4 2 hex);
    in
    "${toString r},${toString g},${toString b}";

  # Rose Pine colors as RGB (from lib.theme)
  c = {
    base00 = hexToRgb theme.base00; # base
    base01 = hexToRgb theme.base01; # surface
    base03 = hexToRgb theme.base03; # muted
    base05 = hexToRgb theme.base05; # text
    base08 = hexToRgb theme.base08; # love
    base0A = hexToRgb theme.base0A; # rose
    base0B = hexToRgb theme.base0B; # pine
    base0D = hexToRgb theme.base0D; # iris
  };

  # Stylix-compatible KDE color scheme using lib.theme
  kdeColors = ''
    BackgroundNormal=${c.base00}
    BackgroundAlternate=${c.base01}
    DecorationFocus=${c.base0D}
    DecorationHover=${c.base0D}
    ForegroundNormal=${c.base05}
    ForegroundActive=${c.base05}
    ForegroundInactive=${c.base05}
    ForegroundLink=${c.base05}
    ForegroundVisited=${c.base05}
    ForegroundNegative=${c.base08}
    ForegroundNeutral=${c.base0D}
    ForegroundPositive=${c.base0B}
  '';

  rosePineColors = pkgs.writeText "RosePine.colors" ''
    [ColorEffects:Disabled]
    ColorEffect=0
    ColorAmount=0
    ContrastEffect=1
    ContrastAmount=0.5
    IntensityEffect=0
    IntensityAmount=0

    [ColorEffects:Inactive]
    ColorEffect=0
    ColorAmount=0
    ContrastEffect=1
    ContrastAmount=0.5
    IntensityEffect=0
    IntensityAmount=0

    [Colors:Button]
    ${kdeColors}

    [Colors:Complementary]
    ${kdeColors}

    [Colors:Selection]
    BackgroundNormal=${c.base0D}
    BackgroundAlternate=${c.base0D}
    DecorationFocus=${c.base0D}
    DecorationHover=${c.base0D}
    ForegroundNormal=${c.base00}
    ForegroundActive=${c.base00}
    ForegroundInactive=${c.base00}
    ForegroundLink=${c.base00}
    ForegroundVisited=${c.base00}
    ForegroundNegative=${c.base08}
    ForegroundNeutral=${c.base0D}
    ForegroundPositive=${c.base0B}

    [Colors:Tooltip]
    ${kdeColors}

    [Colors:View]
    ${kdeColors}

    [Colors:Window]
    ${kdeColors}

    [General]
    Name=Rose Pine
    ColorScheme=RosePine

    [WM]
    activeBlend=${c.base0A}
    activeBackground=${c.base00}
    activeForeground=${c.base05}
    inactiveBlend=${c.base03}
    inactiveBackground=${c.base00}
    inactiveForeground=${c.base05}
  '';
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.kdePackages.breeze
    pkgs.kdePackages.breeze.qt5
    pkgs.kdePackages.breeze-icons
    qtengine.packages.${pkgs.system}.default
  ];

  programs.qtengine = enabled {
    config = {
      theme = {
        colorScheme = "${rosePineColors}";
        iconTheme = "breeze-dark";
        style = "breeze";

        font = {
          family = "Noto Sans";
          size = 11;
          weight = -1;
        };

        fontFixed = {
          family = "Noto Sans";
          size = 11;
          weight = -1;
        };
      };

      misc = {
        singleClickActivate = false;
        menusHaveIcons = true;
        shortcutsForContextMenus = true;
      };
    };
  };
}
