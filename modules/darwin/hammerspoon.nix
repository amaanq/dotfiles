{
  homebrew.casks = [ "hammerspoon" ];

  # Point Hammerspoon to XDG config location
  system.activationScripts.postActivation.text = ''
    for user_home in /Users/*; do
      if [ -d "$user_home" ]; then
        /usr/bin/defaults write org.hammerspoon.Hammerspoon MJConfigFile "$user_home/.config/hammerspoon/init.lua"
      fi
    done
  '';
}
