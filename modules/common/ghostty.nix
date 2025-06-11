{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) merge mkIf enabled;
in
merge
<| mkIf config.isDesktop {
  environment.variables = {
    TERM_PROGRAM = "ghostty";
  };

  home-manager.sharedModules = [
    {
      programs.ghostty = enabled {
        # Don't actually install Ghostty if we are on Darwin.
        # For some reason it is marked as broken.
        package = mkIf config.isDarwin <| pkgs.writeScriptBin "not-ghostty" "";

        installBatSyntax = !config.isDarwin;

        settings = {
          # Font configuration
          font-family = "TX-02 Book";
          font-style = "bold";
          font-size = if config.isDarwin then 13 else 12;
          font-thicken = true;

          # Window settings
          unfocused-split-opacity = 1;
          gtk-titlebar = false;
          gtk-single-instance = true;
          window-theme = "dark";
          mouse-hide-while-typing = true;
          mouse-shift-capture = true;
          mouse-scroll-multiplier = 5;

          # Cursor configuration
          cursor-style = "bar";
          cursor-style-blink = true;
          cursor-invert-fg-bg = true;

          # Shell integration
          shell-integration-features = "cursor,sudo,title";

          # macOS specific
          macos-option-as-alt = true;

          # Clipboard settings
          clipboard-read = "allow";
          clipboard-paste-protection = false;
          copy-on-select = "clipboard";

          # Window behavior
          confirm-close-surface = false;
          quit-after-last-window-closed = true;
          window-save-state = "always";

          # Nerd Font support
          font-codepoint-map = "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6AA,U+E6B2,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0= Symbols Nerd Font Mono";

          # Rosé Pine theme colors
          foreground = "#e0def4";
          background = "#191724";
          selection-foreground = "#e0def4";
          selection-background = "#403d52";
          cursor-color = "#524f67";
          cursor-text = "#e0def4";

          # Color palette (Rosé Pine)
          palette = [
            # black
            "0=#26233a"
            "8=#6e6a86"
            # red
            "1=#eb6f92"
            "9=#eb6f92"
            # green
            "2=#31748f"
            "10=#31748f"
            # yellow
            "3=#f6c177"
            "11=#f6c177"
            # blue
            "4=#9ccfd8"
            "12=#9ccfd8"
            # magenta
            "5=#c4a7e7"
            "13=#c4a7e7"
            # cyan
            "6=#ebbcba"
            "14=#ebbcba"
            # white
            "7=#e0def4"
            "15=#e0def4"
          ];
        };
      };
    }
  ];
}
