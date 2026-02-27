{
  niri,
  niri-src,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    mkForce
    theme
    ;
  niriPackage = niri-src.packages.${config.hostSystem}.niri;

  xdg-desktop-portal-gnome' = pkgs.xdg-desktop-portal-gnome.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./xdg-portal-gnome-screencast-fix.patch ];
  });

  ziplineUpload = pkgs.writeShellScript "zipline-upload" ''
    set -e
    FILE="$1"
    TOKEN=$(cat ${config.secrets.ziplineToken.path})
    RESPONSE=$(${pkgs.curl}/bin/curl -s -X POST "https://i.amaanq.com/api/upload" \
      -H "Authorization: $TOKEN" \
      -F "file=@$FILE")
    URL=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.files[0].url')
    echo -n "$URL" | ${pkgs.wl-clipboard}/bin/wl-copy
    ${pkgs.libnotify}/bin/notify-send "Uploaded" "$URL"
  '';

  validatedConfig =
    pkgs.runCommand "config.kdl"
      {
        config = config.programs.niri.finalConfig;
        passAsFile = [ "config" ];
        buildInputs = [ niriPackage ];
      }
      ''
        niri validate -c $configPath
        cp $configPath $out
      '';
in
{
  imports = [ niri.lib.internal.settings-module ];


  secrets.ziplineToken = {
    file = ./zipline-token.age;
    owner = "amaanq";
  };
  hardware.graphics = enabled;

  services.logind.settings.Login.HandlePowerKey = "ignore";

  programs.dank-material-shell = enabled {
    enableAudioWavelength = false;
    enableCalendarEvents = false;
    enableDynamicTheming = false;
    enableVPN = false;
  };

  services.power-profiles-daemon.enable = mkForce false;
  services.accounts-daemon.enable = mkForce false;

  services.nirinit = enabled {
    settings = {
      launch = {
        helium-browser = "helium";
        "chrome-cinny.amaanq.com__-Default" = "cinny-web-app";
        "chrome-discord.com__app-Default" = "discord-web-app";
        "chrome-app.element.io__-Default" = "element-web-app";
        "chrome-web.telegram.org__a-Default" = "telegram-web-app";
        "chrome-twitter.com__-Default" = "twitter-web-app";
      };
    };
  };

  environment = {
    etc."niri/config.kdl".source = validatedConfig;

    systemPackages = [
      pkgs.brightnessctl
      pkgs.ddcutil
      # Needed for xdg-desktop-portal-gnome 🦼.
      pkgs.gnome-keyring
      pkgs.gifski
      pkgs.inotify-tools
      pkgs.mate.mate-polkit # dms 🦼
      pkgs.nautilus
      pkgs.lxqt.pavucontrol-qt
      pkgs.playerctl
      pkgs.satty
      pkgs.wf-recorder
      pkgs.wl-clipboard
      pkgs.wtype
      pkgs.xdg-utils
      pkgs.xwayland-satellite
    ];

    sessionVariables = {
      CLUTTER_BACKEND = "wayland";
      DISPLAY = ":0";
      GTK_USE_PORTAL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      NIRI_CONFIG = "/etc/niri/config.kdl";
      NIXOS_OZONE_WL = "1";
      NIXOS_XDG_OPEN_USE_PORTAL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QS_NO_RELOAD_POPUP = "1";
      QML_DISABLE_DISK_CACHE = "1";
      QML2_IMPORT_PATH = "${pkgs.qt6.qt5compat}/${pkgs.qt6.qtbase.qtQmlPrefix}";
      SDL_VIDEODRIVER = "wayland";
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
    };
  };

  environment.etc."xdg/satty/config.toml".text = ''
    [general]
    early-exit = true
    copy-command = "wl-copy"
    output-filename = "~/Pictures/Screenshots/screenshot-%Y%m%d-%H%M%S.png"
  '';

  xdg.portal = enabled {
    xdgOpenUsePortal = true;

    extraPortals = mkForce [
      pkgs.gnome-keyring
      xdg-desktop-portal-gnome'
      pkgs.xdg-desktop-portal-gtk
    ];

    config = {
      niri = {
        default = [
          "gnome"
          "gtk"
        ];
        # gnome ScreenCast needs gnome Settings - using gtk Settings can cause crashes
        "org.freedesktop.impl.portal.Settings" = [
          "gtk"
          "gnome"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
    };
  };

  programs.niri = enabled {
    package = niriPackage;

    settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            options = "caps:escape_shifted_capslock,caps:ctrl_modifier";
          };
          repeat-delay = 200;
          repeat-rate = 25;
        };
        mouse = {
          left-handed = true;
          accel-speed = -0.6;
          accel-profile = "flat";
          scroll-factor = 2.0;
        };
        touchpad = {
          tap = true;
        };
      };

      outputs = config.displayOutputs;

      layout = {
        gaps = 8;
        focus-ring.enable = false;
        border = enabled {
          active.color = "#${theme.base0B}";
          inactive.color = "#${theme.base03}";
        };
        preset-column-widths = [
          { proportion = 1. / 4.; }
          { proportion = 1. / 3.; }
          { proportion = 1. / 2.; }
          { proportion = 2. / 3.; }
          { proportion = 3. / 4.; }
          { proportion = 1.; }
        ];
        background-color = "transparent";
      };

      cursor = {
        size = 20;
      };

      screenshot-path = null;
      prefer-no-csd = true;

      spawn-at-startup = [
        { command = [ "xwayland-satellite" ]; }
        { command = [ "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1" ]; }
        {
          command = [
            "dms"
            "run"
          ];
        }
      ];

      window-rules = [
        {
          matches = [ { title = "kitty"; } ];
          opacity = 0.94;
          default-column-width = {
            proportion = 0.6;
          };
        }
        {
          matches = [ { app-id = "^chrome-discord\\.com__app-Default$"; } ];
          default-column-width = {
            proportion = 0.65;
          };
        }
        {
          matches = [ { app-id = "^spotify$"; } ];
          default-column-width = {
            proportion = 0.35;
          };
        }
        {
          matches = [
            {
              app-id = "^steam$";
              title = "^notificationtoasts_\\d+_desktop$";
            }
          ];
          open-focused = false;
          default-floating-position = {
            x = 0;
            y = 0;
            relative-to = "bottom-right";
          };
        }
      ];

      layer-rules = [
        {
          matches = [ { } ];
          place-within-backdrop = true;
        }
      ];

      binds = {
        "Mod+Shift+Slash".action.show-hotkey-overlay = { };

        # Applications
        "Mod+Return".action.spawn = "kitty";
        "Mod+E".action.spawn = "thunar";
        "Mod+O".action.spawn = "ida";

        # DMS
        "Mod+Alt+V".action.spawn = [
          "dms"
          "ipc"
          "call"
          "clipboard"
          "toggle"
        ];
        "Mod+Alt+N".action.spawn = [
          "dms"
          "ipc"
          "call"
          "notifications"
          "toggle"
        ];
        "Mod+R".action.spawn = [
          "dms"
          "ipc"
          "call"
          "spotlight"
          "toggle"
        ];
        "Mod+X".action.spawn = [
          "dms"
          "ipc"
          "call"
          "powermenu"
          "toggle"
        ];

        # Window management
        "Mod+Escape".action.quit = { };
        "Mod+Space".action.toggle-overview = { };
        "Mod+C".action.close-window = { };
        "Mod+V".action.toggle-window-floating = { };

        # Window navigation
        "Mod+H".action.focus-column-left-or-last = { };
        "Mod+J".action.focus-window-down = { };
        "Mod+K".action.focus-window-up = { };
        "Mod+L".action.focus-column-right-or-first = { };

        # Window movement
        "Mod+Shift+H".action.move-column-left = { };
        "Mod+Shift+J".action.move-window-down = { };
        "Mod+Shift+K".action.move-window-up = { };
        "Mod+Shift+L".action.move-column-right = { };

        # Window resizing
        "Mod+Alt+H".action.set-column-width = "-20";
        "Mod+Alt+J".action.set-window-height = "+20";
        "Mod+Alt+K".action.set-window-height = "-20";
        "Mod+Alt+L".action.set-column-width = "+20";

        "Mod+Home".action.focus-column-first = { };
        "Mod+End".action.focus-column-last = { };
        "Mod+Ctrl+Home".action.move-column-to-first = { };
        "Mod+Ctrl+End".action.move-column-to-last = { };

        # Monitor navigation
        "Mod+Left".action.focus-monitor-left = { };
        "Mod+Right".action.focus-monitor-right = { };

        # Move window/column to monitor
        "Mod+Shift+Left".action.move-column-to-monitor-left = { };
        "Mod+Shift+Right".action.move-column-to-monitor-right = { };

        "Mod+Page_Down".action.focus-workspace-down = { };
        "Mod+Page_Up".action.focus-workspace-up = { };
        "Mod+U".action.focus-workspace-down = { };
        "Mod+I".action.focus-workspace-up = { };
        "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
        "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
        "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
        "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

        "Mod+Shift+Page_Down".action.move-workspace-down = { };
        "Mod+Shift+Page_Up".action.move-workspace-up = { };
        "Mod+Shift+U".action.move-workspace-down = { };
        "Mod+Shift+I".action.move-workspace-up = { };

        "Mod+WheelScrollDown" = {
          cooldown-ms = 150;
          action.focus-workspace-down = { };
        };
        "Mod+WheelScrollUp" = {
          cooldown-ms = 150;
          action.focus-workspace-up = { };
        };
        "Mod+Ctrl+WheelScrollDown" = {
          cooldown-ms = 150;
          action.move-column-to-workspace-down = { };
        };
        "Mod+Ctrl+WheelScrollUp" = {
          cooldown-ms = 150;
          action.move-column-to-workspace-up = { };
        };

        "Mod+WheelScrollRight".action.focus-column-right = { };
        "Mod+WheelScrollLeft".action.focus-column-left = { };
        "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
        "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };

        "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
        "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
        "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
        "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;
        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;

        "Mod+Comma".action.consume-window-into-column = { };
        "Mod+Period".action.expel-window-from-column = { };

        "Mod+Ctrl+R".action.switch-preset-column-width = { };
        "Mod+Shift+R".action.reset-window-height = { };
        "Mod+F".action.fullscreen-window = { };
        "Mod+D".action.maximize-column = { };
        "Mod+G".action.expand-column-to-available-width = { };
        "Mod+Ctrl+C".action.center-column = { };
        "Mod+Shift+F".action.center-visible-columns = { };

        "Mod+Minus".action.set-column-width = "-20";
        "Mod+Equal".action.set-column-width = "+20";

        "Mod+Shift+Minus".action.set-window-height = "-20";
        "Mod+Shift+Equal".action.set-window-height = "+20";

        "Mod+Shift+S".action.screenshot = {
          show-pointer = false;
        };

        # Screenshot with annotation
        "Mod+Shift+A".action.spawn = [
          "sh"
          "-c"
          "rm -f /tmp/screenshot.png; niri msg action screenshot --path /tmp/screenshot.png; inotifywait -q -e close_write --include screenshot.png /tmp && satty --filename /tmp/screenshot.png"
        ];

        # Screenshot with annotation + upload to Zipline
        "Mod+Shift+D".action.spawn = [
          "sh"
          "-c"
          "rm -f /tmp/screenshot.png; niri msg action screenshot --path /tmp/screenshot.png; inotifywait -q -e close_write --include screenshot.png /tmp && satty --filename /tmp/screenshot.png --output-filename /tmp/annotated.png --early-exit && ${ziplineUpload} /tmp/annotated.png"
        ];

        "Mod+Shift+T".action.spawn = [
          "sh"
          "-c"
          "wf-recorder -g \"$(slurp)\" -f /tmp/recording_$(date +%Y%m%d_%H%M%S).mp4"
        ];

        "Mod+Shift+E".action.quit = { };
        "Mod+Shift+P".action.power-off-monitors = { };

        # Audio controls
        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action.spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "0.05+"
          ];
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action.spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "0.05-"
          ];
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action.spawn = [
            "wpctl"
            "set-mute"
            "@DEFAULT_AUDIO_SINK@"
            "toggle"
          ];
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action.spawn = [
            "wpctl"
            "set-mute"
            "@DEFAULT_AUDIO_SOURCE@"
            "toggle"
          ];
        };

        # Brightness controls
        "XF86MonBrightnessUp" = {
          allow-when-locked = true;
          action.spawn = [
            "brightnessctl"
            "s"
            "10%+"
          ];
        };
        "XF86MonBrightnessDown" = {
          allow-when-locked = true;
          action.spawn = [
            "brightnessctl"
            "s"
            "10%-"
          ];
        };

        # Media controls
        "XF86AudioNext" = {
          allow-when-locked = true;
          action.spawn = [
            "playerctl"
            "next"
          ];
        };
        "XF86AudioPrev" = {
          allow-when-locked = true;
          action.spawn = [
            "playerctl"
            "previous"
          ];
        };
        "XF86AudioPlay" = {
          allow-when-locked = true;
          action.spawn = [
            "playerctl"
            "play-pause"
          ];
        };
        "XF86AudioPause" = {
          allow-when-locked = true;
          action.spawn = [
            "playerctl"
            "play-pause"
          ];
        };
      };
    };
  };
}
