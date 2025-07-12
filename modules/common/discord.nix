{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) merge mkIf;
in
merge
<| mkIf config.isDesktop {
  home-manager.sharedModules = [
    {
      xdg.configFile."Vencord/settings/quickCss.css".text = config.theme.discordCss;
    }
  ];

  unfree.allowedNames = [
    "discord"
  ];

  environment.systemPackages =
    let
      inherit (lib) attrValues optionalAttrs;

      krisp-patcher =
        pkgs.writers.writePython3Bin "krisp-patcher"
          {
            libraries = with pkgs.python3Packages; [
              capstone
              pyelftools
            ];
            flakeIgnore = [
              "E501" # line too long (82 > 79 characters)
              "F403" # 'from module import *' used; unable to detect undefined names
              "F405" # name may be undefined, or defined from star imports: module
            ];
          }
          (
            builtins.readFile (
              pkgs.fetchurl {
                url = "https://raw.githubusercontent.com/sersorrel/sys/afc85e6b249e5cd86a7bcf001b544019091b928c/hm/discord/krisp-patcher.py";
                sha256 = "sha256-h8Jjd9ZQBjtO3xbnYuxUsDctGEMFUB5hzR/QOQ71j/E=";
              }
            )
          );

      baseDiscord = pkgs.discord.override {
        withOpenASAR = true;
        withVencord = true;
      };
    in
    [
      krisp-patcher
    ]
    ++ attrValues (
      optionalAttrs config.isLinux {
        discord = baseDiscord.overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.makeWrapper ];
          postFixup = ''
            wrapProgram $out/opt/Discord/Discord \
              --set ELECTRON_OZONE_PLATFORM_HINT "auto" \
              --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
          '';
        });
      }
      // optionalAttrs config.isDarwin {
        discord = baseDiscord;
      }
    )
    ++ [
      pkgs.legcord
    ];
}
