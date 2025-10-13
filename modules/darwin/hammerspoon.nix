{
  homebrew.casks = [ "hammerspoon" ];

  home-manager.sharedModules = [
    {
      xdg.configFile."hammerspoon/init.lua".text = "";

      home.activation.setHammerspoonConfig = ''
        $DRY_RUN_CMD /usr/bin/defaults write org.hammerspoon.Hammerspoon MJConfigFile ~/.config/hammerspoon/init.lua
      '';
    }
  ];
}
