{
  config,
  lib,
  ...
}:
let
  inherit (lib) merge mkIf enabled;
in
merge
<| mkIf config.isDesktop {
  home-manager.sharedModules = [
    {
      programs.hyprpanel = enabled {
        systemd.enable = true;

        settings = {
          scalingPriority = "hyprland";
          theme = {
            bar = {
              transparent = true;
            };
            font = {
              size = "1rem";
            };
          };
          layout = {
            bar.layouts = {
              "0" = {
                left = [
                  "dashboard"
                  "workspaces"
                  "windowtitle"
                  "cpu"
                  "ram"
                  "netstat"
                  "updates"
                ];
                middle = [ "media" ];
                right = [
                  "hyprsunset"
                  "volume"
                  "network"
                  "bluetooth"
                  "systray"
                  "clock"
                  "notifications"
                  "power"
                ];
              };
              "1" = {
                left = [
                  "dashboard"
                  "workspaces"
                  "windowtitle"
                  "cpu"
                  "ram"
                  "netstat"
                  "updates"
                ];
                middle = [ "media" ];
                right = [
                  "hyprsunset"
                  "volume"
                  "network"
                  "bluetooth"
                  "systray"
                  "clock"
                  "notifications"
                  "power"
                ];
              };
            };
          };
        };
      };
    }
  ];
}
