{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    enabled
    merge
    mkIf
    flatten
    range
    ;

  rosePineColors = config.rosePineColors;

  gamemode-script = pkgs.writeShellScript "gamemode" ''
    HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
    if [ "$HYPRGAMEMODE" = 1 ]; then
      hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:drop_shadow 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
      exit
    fi
    hyprctl reload
  '';
in
merge
<| mkIf config.isDesktop {
  hardware.graphics = enabled;

  services.logind.powerKey = "ignore";

  xdg.portal = enabled {
    xdgOpenUsePortal = true;

    config.common.default = "*";

    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
    ];

    configPackages = [
      pkgs.hyprland
    ];
  };

  programs.xwayland = enabled;

  environment.systemPackages = attrValues {
    inherit (pkgs)
      aquamarine
      brightnessctl
      copyq
      gifski
      grim
      hypridle
      hyprlock
      hyprpicker
      hyprpolkitagent
      hyprsunset
      hyprsysteminfo
      hyprland-qt-support
      pavucontrol
      playerctl
      rofi-wayland
      rofi-emoji
      slurp
      swappy
      wf-recorder
      wl-clipboard
      wtype
      xdg-utils
      ;
    inherit (pkgs.kdePackages) xwaylandvideobridge;
  };

  programs.hyprland = enabled {
    xwayland.enable = true;
  };

  home-manager.sharedModules = [
    {
      # Hint Electron apps to use Wayland:
      home.sessionVariables.NIXOS_OZONE_WL = "1";

      # Proper theme configuration for Hyprland
      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.rose-pine-hyprcursor;
        name = "rose-pine-hyprcursor";
        size = 24;
      };

      wayland.windowManager.hyprland = enabled {
        package = null;
        portalPackage = null;

        systemd = enabled {
          enableXdgAutostart = true;
          variables = [ "--all" ];
        };

        settings = {
          # Monitor configuration
          monitor = [
            "DP-1, 3840x2160@240, 3072x0, 1.25"
            "DP-2, 3840x2160@160, 0x0, 1.25"
          ];

          # Environment variables
          env = [
            "CLUTTER_BACKEND,wayland"
            "GDK_BACKEND,wayland"
            "GDK_DPI_SCALE,1"
            "GDK_SCALE,1"
            "QT_AUTO_SCREEN_SCALE_FACTOR,1"
            "QT_QPA_PLATFORM,wayland;xcb"
            "QT_QPA_PLATFORMTHEME,qt6ct"
            "QT_STYLE_OVERRIDE,kvantum"
            "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
            "QT_SCALE_FACTOR_ROUNDING_POLICY,RoundPreferFloor"
            "SDL_VIDEODRIVER,wayland"
            "ELECTRON_OZONE_PLATFORM_HINT,auto"
            "MOZ_ENABLE_WAYLAND,1"
          ];

          # XWayland configuration
          xwayland = {
            force_zero_scaling = true;
          };

          # Variables
          "$terminal" = "kitty";
          "$fileManager" = "dolphin";
          "$menu" = "rofi -show drun";
          "$ida" = "ida";

          # Startup applications
          exec-once = [
            "systemctl --user start hyprpolkitagent"
            "copyq --start-server"
            "hyprpanel"
            "hypridle"
            "hyprpaper"
            "xwaylandvideobridge"
            "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
            "thorium"
            "kitty"
            "spotify"
            "discord"
          ];

          # Input configuration
          input = {
            kb_layout = "us";
            kb_options = "caps:escape_shifted_capslock,caps:ctrl_modifier";

            float_switch_override_focus = 0;
            follow_mouse = 2;
            repeat_rate = 25;
            repeat_delay = 200;
            sensitivity = -0.6;
            accel_profile = "flat";
            scroll_factor = 2.0;
            left_handed = true;

            touchpad = {
              natural_scroll = false;
            };
          };

          # Gestures
          gestures = {
            workspace_swipe = false;
          };

          # General settings
          general = {
            allow_tearing = true;
            gaps_in = 10;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "0xff${rosePineColors.pine} 0xff${rosePineColors.foam} 90deg";
            "col.inactive_border" = "0xff${rosePineColors.muted}";
            layout = "dwindle";
          };

          # Decoration
          decoration = {
            rounding = 8;

            blur = {
              enabled = true;
              size = 4;
              passes = 3;
              ignore_opacity = true;
              popups = true;
            };

            shadow = {
              enabled = true;
              ignore_window = true;
              offset = "2 2";
              range = 8;
              render_power = 2;
              color = "0x66000000";
            };
          };

          # Animations
          animations = {
            enabled = true;

            bezier = [
              "overshot, 0.05, 0.9, 0.1, 1.05"
              "smoothOut, 0.36, 0, 0.66, -0.56"
              "smoothIn, 0.25, 1, 0.5, 1"
              "linear, 0.0, 0.0, 1.0, 1.0"
            ];

            animation = [
              "windows, 1, 3, overshot, slide"
              "windowsOut, 1, 2, smoothOut, slide"
              "windowsMove, 1, 2, default"
              "border, 1, 10, default"
              "fade, 1, 2, smoothIn"
              "fadeDim, 1, 2, smoothIn"
              "workspaces, 1, 3, default"
              "specialWorkspace, 1, 2, default, slidevert"
              "borderangle, 1, 100, linear, loop"
            ];
          };

          # Dwindle layout
          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          # Master layout
          master = {
            new_status = "master";
          };

          # Misc settings
          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = false;
          };

          # Groups
          group = {
            "col.border_active" = "0xff${rosePineColors.pine} 0xff${rosePineColors.foam} 90deg";
            "col.border_inactive" = "0xff${rosePineColors.muted}";

            groupbar = {
              "col.active" = "0xff${rosePineColors.overlay}";
              "col.inactive" = "0xff${rosePineColors.surface}";
              font_size = 12;
              height = 16;
              indicator_height = 4;
              rounding = 3;
              gradient_rounding = 4;
              gradients = true;
            };
          };

          # Window rules
          windowrulev2 = [
            "suppressevent maximize, class:.*"
            "stayfocused, title:^()$,class:^(steam)$"
            "minsize 1 1, title:^()$,class:^(steam)$"
            "float, class:^(Steam)$,title:^(Friends List)$"
            "float, class:^(Steam)$,title:^(Steam - News)$"
            "immediate, class:^(cs2)$"
            "opacity 0.94 0.94,class:^(com.mitchellh.ghostty|kitty|discord|Spotify)$"
            "opacity 0.0 override, class:^(xwaylandvideobridge)$"
            "noanim, class:^(xwaylandvideobridge)$"
            "noinitialfocus, class:^(xwaylandvideobridge)$"
            "maxsize 1 1, class:^(xwaylandvideobridge)$"
            "noblur, class:^(xwaylandvideobridge)$"
          ];

          # Key bindings
          bind = flatten [
            # Basic window management
            "SUPER, Return, exec, $terminal"
            "SUPER, C, killactive,"
            "SUPER, M, exit,"
            "SUPER, E, exec, $fileManager"
            "SUPER, V, togglefloating,"
            "SUPER, R, exec, $menu"
            "SUPER, period, exec, killall rofi; rofi -show emoji -emoji-format \"{emoji}\" -modi emoji -theme ~/.config/rofi/global/emoji -normal-window"
            "SUPER, P, pseudo,"
            "SUPER, O, togglesplit,"
            "SUPER, I, exec, $ida"
            "SUPER, F, fullscreen, 1"
            "SUPER, D, fullscreen, 0"

            # Focus movement (HJKL)
            "SUPER, H, movefocus, l"
            "SUPER, J, movefocus, d"
            "SUPER, K, movefocus, u"
            "SUPER, L, movefocus, r"

            # Window movement
            "SUPER SHIFT, H, movewindow, l"
            "SUPER SHIFT, J, movewindow, d"
            "SUPER SHIFT, K, movewindow, u"
            "SUPER SHIFT, L, movewindow, r"

            # Window resizing
            "SUPER ALT, H, resizeactive, -20 0"
            "SUPER ALT, J, resizeactive, 0 20"
            "SUPER ALT, K, resizeactive, 0 -20"
            "SUPER ALT, L, resizeactive, 20 0"

            # Screenshots
            "SUPER, PRINT, exec, grim -g \"$(swappy -w)\" - | swappy -f -"
            ", PRINT, exec, grim - | swappy -f -"
            "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | tee >(wl-copy) | swappy -f -"

            # Recording
            "SUPER SHIFT, R, exec, wf-recorder -g \"$(slurp)\" -f /tmp/recording_$(date +%Y%m%d_%H%M%S).mp4"
            ''SUPER SHIFT, ESCAPE, exec, pkill -SIGINT wf-recorder; sleep 1; latest=$(find /tmp -name "recording_*.mp4" -type f -printf "%T@ %p\n" | sort -nr | head -n1 | cut -d' ' -f2-); if [ -n "$latest" ]; then output_gif="$HOME/Pictures/$(basename "$latest" .mp4).gif"; gifski -o "$output_gif" "$latest" && notify-send "GIF saved to Pictures: $(basename "$output_gif")"; else notify-send "No recording found"; fi''

            # Special workspace
            "SUPER, S, togglespecialworkspace, magic"
            "SUPER ALT, S, movetoworkspace, special:magic"

            # Workspace scrolling
            "SUPER, mouse_down, workspace, e+1"
            "SUPER, mouse_up, workspace, e-1"

            # Groups
            "SUPER, t, togglegroup"
            "SUPER, grave, changegroupactive"
            "SUPER SHIFT, grave, changegroupactive, b"

            # Gamemode
            "WIN, F1, exec, ${gamemode-script}"

            # Workspace switching and moving
            (map (n: [
              "SUPER, ${toString n}, workspace, ${toString n}"
              "SUPER SHIFT, ${toString n}, movetoworkspace, ${toString n}"
            ]) (range 1 9))
            "SUPER, 0, workspace, 10"
            "SUPER SHIFT, 0, movetoworkspace, 10"
          ];

          # Mouse bindings
          bindm = [
            "SUPER, mouse:272, movewindow"
            "SUPER, mouse:273, resizewindow"
          ];

          # Media keys
          bindel = [
            ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
            ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
            ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
          ];

          # Media control
          bindl = [
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPrev, exec, playerctl previous"
          ];

          # Plugin configuration
          plugin = {
            hyprexpo = {
              columns = 3;
              gap_size = 5;
              bg_col = "rgb(111111)";
              workspace_method = "center current";
              enable_gesture = true;
              gesture_fingers = 3;
              gesture_distance = 300;
              gesture_positive = true;
            };

            hyprbars = {
              bar_height = 20;
              bar_color = "rgb(1e1e1e)";
              "col.text" = "0xff${rosePineColors.foam}";
              bar_text_size = 12;
              bar_button_padding = 8;
              bar_padding = 10;
              bar_precedence_over_border = true;
              "hyprbars-button" = [
                "rgb(1e1e1e), 20, , hyprctl dispatch killactive"
                "rgb(1e1e1e), 20, , hyprctl dispatch fullscreen 2"
                "rgb(1e1e1e), 20, , hyprctl dispatch togglefloating"
              ];
            };
          };
        };
      };

    }
  ];
}
