{
  config,
  lib,
  pkgs,
  ...
}:
let
  ghostty-wrapped = pkgs.symlinkJoin {
    name = "ghostty";
    paths = [ pkgs.ghostty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/ghostty
      makeWrapper ${pkgs.ghostty}/bin/ghostty $out/bin/ghostty \
        --add-flags "--config-file=/etc/ghostty/config"
    '';
    inherit (pkgs.ghostty) meta;
  };
in
lib.mkIf config.isDesktop {
  environment.systemPackages = lib.mkIf config.isLinux [ ghostty-wrapped ];

  environment.variables.TERM_PROGRAM = "ghostty";

  environment.etc."ghostty/config".text = ''
    # Font configuration
    font-family = TX-02 Medium
    font-size = ${toString (if config.isDarwin then 13 else 11)}
    font-thicken = true
    font-codepoint-map = U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6AA,U+E6B2,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0= Symbols Nerd Font Mono

    # Window settings
    unfocused-split-opacity = 1
    gtk-titlebar = false
    gtk-single-instance = true
    window-theme = dark
    mouse-hide-while-typing = true
    mouse-shift-capture = true
    mouse-scroll-multiplier = ${toString (if config.isDarwin then 5 else 1)}

    # Cursor configuration
    cursor-style = bar
    cursor-style-blink = true
    cursor-invert-fg-bg = true

    # Shell integration
    shell-integration-features = cursor,sudo,title

    # macOS specific
    macos-option-as-alt = true

    # Clipboard settings
    clipboard-read = allow
    clipboard-paste-protection = false
    copy-on-select = clipboard

    # Window behavior
    confirm-close-surface = false
    quit-after-last-window-closed = true
    window-save-state = always

    # Rose Pine theme colors
    foreground = e0def4
    background = 191724
    selection-foreground = e0def4
    selection-background = 403d52
    cursor-color = 524f67
    cursor-text = e0def4

    # Color palette (Rose Pine)
    palette = 0=#26233a
    palette = 8=#6e6a86
    palette = 1=#eb6f92
    palette = 9=#eb6f92
    palette = 2=#31748f
    palette = 10=#31748f
    palette = 3=#f6c177
    palette = 11=#f6c177
    palette = 4=#9ccfd8
    palette = 12=#9ccfd8
    palette = 5=#c4a7e7
    palette = 13=#c4a7e7
    palette = 6=#ebbcba
    palette = 14=#ebbcba
    palette = 7=#e0def4
    palette = 15=#e0def4
  '';
}
