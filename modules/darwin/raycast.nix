{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.raycast
  ];

  system.defaults.CustomSystemPreferences."com.apple.symbolichotkeys" = {
    AppleSymbolicHotKeys = {
      # Disable Spotlight
      "64" = {
        enabled = false;
        value = {
          parameters = [
            65535
            49
            1048576
          ];
          type = "standard";
        };
      };
    };
  };

  home-manager.sharedModules = [
    {
      home.activation.setRaycastHotkey = ''
        # Wait for Raycast to be installed
        if [ -d "/Applications/Raycast.app" ]; then
          # Set Raycast hotkey to Option+R (no clue why it's 15)
          $DRY_RUN_CMD /usr/bin/defaults write com.raycast.macos raycastGlobalHotkey -string "Option-15"
        fi
      '';
    }
  ];
}
