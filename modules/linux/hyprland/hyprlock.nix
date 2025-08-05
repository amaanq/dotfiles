{
  config,
  lib,
  ...
}:
let
  inherit (lib) enabled merge mkIf;

  rosePineColors = config.rosePineColors;
in
merge
<| mkIf config.isDesktop {
  home-manager.sharedModules = [
    {
      programs.hyprlock = enabled {
        settings = {
          general = {
            hide_cursor = true;
            ignore_empty_input = true;
            text_trim = true;
          };

          background = [
            {
              monitor = "";
              path = "screenshot";
              blur_passes = 4;
              blur_size = 10;
              contrast = 0.8916;
              brightness = 0.7172;
              vibrancy = 0.1696;
              vibrancy_darkness = 0;
            }
          ];

          label = [
            {
              monitor = "";
              text = "$TIME12";
              color = "rgba(255, 255, 255, 1)";
              shadow_size = 3;
              shadow_color = "rgb(0,0,0)";
              shadow_boost = 1.2;
              font_size = 150;
              font_family = "Berkeley Mono";
              position = "0, -250";
              halign = "center";
              valign = "top";
            }
            {
              monitor = "";
              text = "cmd[update:1000] echo -e \"$(date +\"%A, %B %-d, %Y\")\"";
              color = "rgba(255, 255, 255, 1)";
              font_size = 17;
              font_family = "Berkeley Mono";
              position = "0, -130";
              halign = "center";
              valign = "center";
            }
            {
              monitor = "";
              text = "cmd[update:60000] echo \"<b>up $(awk '{d=int($1/86400); h=int(($1%86400)/3600); m=int(($1%3600)/60); if (d>0) printf \"%dd %dh %dm\", d, h, m; else if (h>0) printf \"%dh %dm\", h, m; else printf \"%dm\", m}' /proc/uptime)</b>\"";
              color = "0xff${rosePineColors.iris}";
              font_size = 14;
              font_family = "Inter Display Medium";
              position = "0, -0.005";
              halign = "center";
              valign = "bottom";
            }
          ];

          input-field = [
            {
              monitor = "";
              size = "250, 60";
              outline_thickness = 0;
              outer_color = "rgba(0, 0, 0, 0)";
              dots_size = 0.1;
              dots_spacing = 1;
              dots_center = true;
              inner_color = "rgba(0, 0, 0, 0)";
              font_color = "rgba(200, 200, 200, 1)";
              fade_on_empty = false;
              font_family = "Berkeley Mono";
              placeholder_text = "<span> $USER</span>";
              hide_input = false;
              position = "0, -470";
              halign = "center";
              valign = "center";
              zindex = 10;
            }
          ];
        };
      };
    }
  ];
}
