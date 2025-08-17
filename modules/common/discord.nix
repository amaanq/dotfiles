{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) merge mkIf optional;
in
merge
<| mkIf config.isDesktop {
  unfree.allowedNames = [
    "discord"
  ];
  environment.systemPackages =
    let
      krisp-patcher =
        pkgs.writers.writePython3Bin "krisp-patcher"
          {
            libraries = [
              pkgs.python3Packages.capstone
              pkgs.python3Packages.pyelftools
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

      discordPackage =
        if config.isLinux then
          pkgs.symlinkJoin {
            name = "discord-patched";
            paths = [ baseDiscord ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              # Remove the original Discord binary
              rm $out/bin/discord

              # Create our patching wrapper
              makeWrapper ${baseDiscord}/bin/discord $out/bin/discord \
                --run '
                  LATEST_DIR=$(ls -1v ~/.config/discord/ 2>/dev/null | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | tail -n1)

                  if [ -n "$LATEST_DIR" ]; then
                    KRISP_FILE="$HOME/.config/discord/$LATEST_DIR/modules/discord_krisp/discord_krisp.node"

                    if [ -f "$KRISP_FILE" ]; then
                      if ${pkgs.ripgrep}/bin/rg -q "dualcontourmaybe" "$KRISP_FILE" 2>/dev/null; then
                        echo "Patching Krisp in version $LATEST_DIR..."
                        ${krisp-patcher}/bin/krisp-patcher "$KRISP_FILE" || echo "Warning: Failed to patch Krisp"
                      fi
                    fi
                  fi
                ' \
                --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
            '';
          }
        else if config.isDarwin then
          baseDiscord
        else
          null;
    in
    [
      krisp-patcher
    ]
    ++ optional (discordPackage != null) discordPackage;
}
