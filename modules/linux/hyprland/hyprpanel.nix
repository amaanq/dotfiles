{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) merge mkIf enabled;
in
merge
<| mkIf config.isDesktop {
  home-manager.sharedModules = [
    {
      imports = [ inputs.hyprpanel.homeManagerModules.hyprpanel ];

      programs.hyprpanel = enabled {
        systemd.enable = true;
        hyprland.enable = true;
        overwrite.enable = true;

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
