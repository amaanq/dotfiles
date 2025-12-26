{
  dankMaterialShell,
  niri-src,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
  niriPackage = niri-src.packages.${pkgs.system}.niri;

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
in
{
  imports = [
    dankMaterialShell.nixosModules.greeter
  ];
}
// merge
<| mkIf config.isDesktop {
  secrets.ziplineToken = {
    file = ./zipline-token.age;
    owner = "amaanq";
  };
  hardware.graphics = enabled;

  services.logind.settings.Login.HandlePowerKey = "ignore";

  programs.niri = enabled {
    package = niriPackage;
  };

  services.nirinit = enabled {
    settings = {
      launch = {
        thorium-browser = "thorium";
        "thorium-cinny.amaanq.com__-Default" = "cinny-web-app";
        "thorium-discord.com__app-Default" = "discord-web-app";
        "thorium-app.element.io__-Default" = "element-web-app";
        "thorium-web.telegram.org__a-Default" = "telegram-web-app";
        "thorium-twitter.com__-Default" = "twitter-web-app";
      };
    };
  };

  environment = {
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
      pkgs.swww
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

  xdg.portal = enabled {
    xdgOpenUsePortal = true;

    extraPortals = [
      pkgs.gnome-keyring
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];

    config = {
      niri = {
        default = [
          "gnome"
          "gtk"
        ];
      };
    };
  };

  home-manager.sharedModules = [
    (
      { osConfig, lib, ... }:
      lib.mkIf osConfig.isDesktop {
        programs.dank-material-shell = enabled {
          enableDynamicTheming = false;
        };

        programs.niri = {
          package = niriPackage;
          settings = {
            layer-rules = [
              {
                matches = [ { } ]; # matches all layers
                place-within-backdrop = true;
              }
            ];

            layout = {
              gaps = 8;
              focus-ring = {
                width = 2;
                active.color = "#c4a7e7";
              };

              preset-column-widths = [
                { proportion = 1. / 3.; }
                { proportion = 2. / 3.; }
              ];

              background-color = "transparent";
            };

            spawn-at-startup = [
              { command = [ "xwayland-satellite" ]; }
              { command = [ "quickshell" ]; }
              { command = [ "thorium" ]; }
              { command = [ "kitty" ]; }
              { command = [ "spotify" ]; }
              { command = [ "discord-web-app" ]; }
              { command = [ "element-web-app" ]; }
              { command = [ "cinny-web-app" ]; }
              { command = [ "twitter-web-app" ]; }
              { command = [ "swww-daemon" ]; }
              {
                command = [
                  "stash"
                  "watch"
                ];
              }
              {
                command = [ "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1" ];
              }
              {
                command = [
                  "dms"
                  "run"
                ];
              }
            ];

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
                natural-scroll = false;
              };
            };

            outputs = osConfig.displayOutputs;

            cursor = {
              size = 20;
            };

            screenshot-path = null;

            prefer-no-csd = true;

            window-rules = [
              {
                matches = [
                  { title = "kitty"; }
                ];
                opacity = 0.94;
                default-column-width = {
                  proportion = 0.6;
                };
              }
              {
                matches = [
                  { app-id = "^thorium-discord\\.com__app-Default$"; }
                ];
                default-column-width = {
                  proportion = 0.65;
                };
              }
              {
                matches = [
                  { app-id = "^spotify$"; }
                ];
                default-column-width = {
                  proportion = 0.35;
                };
              }
            ];

            binds = {
              # shows a list of important hotkeys.
              "Mod+Shift+Slash".action.show-hotkey-overlay = { };

              # Applications
              "Mod+Return".action.spawn = "kitty";
              "Mod+E".action.spawn = "thunar";
              "Mod+O".action.spawn = "ida";

              # dms
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
              "Mod+Ctrl+C".action.center-column = { };
              "Mod+Shift+F".action.center-visible-columns = { }; # Fit all visible columns to monitor

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

              # The quit action will show a confirmation dialog to avoid accidental exits.
              "Mod+Shift+E".action.quit = { };

              # Powers off the monitors. To turn them back on, do any input like
              # moving the mouse or pressing any other key.
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

        xdg.configFile."satty/config.toml".text = ''
          [general]
          early-exit = true
          copy-command = "wl-copy"
          output-filename = "~/Pictures/Screenshots/screenshot-%Y%m%d-%H%M%S.png"
        '';
      }
    )
  ];
}
