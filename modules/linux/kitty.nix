{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  home-manager.sharedModules = [
    {
      programs.kitty = enabled {
        font = {
          name = "TX-02 Book";
          size = 11;
        };

        shellIntegration.enableBashIntegration = false;
        shellIntegration.enableZshIntegration = false;

        settings = {
          # Shell and performance
          shell = "${pkgs.nushell}/bin/nu";
          repaint_delay = 6;
          input_delay = 1;
          sync_to_monitor = false;

          # Text selection and editing
          copy_on_select = true;
          strip_trailing_spaces = "always";

          # Cursor settings
          cursor_shape = "block";
          cursor_blink_interval = 0.75;
          cursor_stop_blinking_after = 30.0;

          # Window settings
          window_border_width = "1px";
          initial_window_width = 800;
          initial_window_height = 600;
          remember_window_size = false;

          # Audio
          enable_audio_bell = false;
          window_alert_on_bell = true;
          bell_on_tab = false;

          # Shell integration and updates
          shell_integration = "enabled no-cursor";
          update_check_interval = 0;

          # Scrollback
          scrollback_lines = 500000;

          # Symbol mapping for Nerd Fonts
          symbol_map = "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6AA,U+E6B2,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0 Symbols Nerd Font Mono";

          # Rose Pine theme colors
          foreground = "#e0def4";
          background = "#191724";
          selection_foreground = "#e0def4";
          selection_background = "#403d52";

          cursor = "none";
          cursor_text_color = "#e0def4";

          url_color = "#c4a7e7";

          active_tab_foreground = "#e0def4";
          active_tab_background = "#26233a";
          inactive_tab_foreground = "#6e6a86";
          inactive_tab_background = "#191724";

          active_border_color = "none";
          inactive_border_color = "#403d52";
          tab_bar_background = "#3a3752";

          # Color palette
          color0 = "#26233a";
          color8 = "#6e6a86";
          color1 = "#eb6f92";
          color9 = "#eb6f92";
          color2 = "#31748f";
          color10 = "#31748f";
          color3 = "#f6c177";
          color11 = "#f6c177";
          color4 = "#9ccfd8";
          color12 = "#9ccfd8";
          color5 = "#c4a7e7";
          color13 = "#c4a7e7";
          color6 = "#ebbcba";
          color14 = "#ebbcba";
          color7 = "#e0def4";
          color15 = "#e0def4";
        };
      };
    }
  ];
}
