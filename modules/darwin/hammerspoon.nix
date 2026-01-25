{
  homebrew.casks = [ "hammerspoon" ];

  # Point Hammerspoon directly to /etc/hammerspoon
  system.activationScripts.postActivation.text = ''
    /usr/bin/defaults write org.hammerspoon.Hammerspoon MJConfigFile /etc/hammerspoon/init.lua
  '';
}
