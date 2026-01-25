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

  # Set Raycast hotkey to Option+R
  system.activationScripts.postActivation.text = ''
    if [ -d "/Applications/Raycast.app" ]; then
      /usr/bin/defaults write com.raycast.macos raycastGlobalHotkey -string "Option-15"
    fi
  '';
}
