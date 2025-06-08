{ config, lib, ... }:
let
  inherit (lib) attrNames head enabled;
  user = head (attrNames config.users.users);
in
{
  age.secrets.atuin-key = {
    file = ./key.age;
    owner = user;
  };

  home-manager.sharedModules = [
    {
      programs.atuin = enabled {
        daemon = enabled {
          logLevel = "error";
        };

        # (lol sphere)
        # No because we are doing it at build time instead of the way
        # this retarded module does it. Why the hell do you generate
        # the config every time the shell is launched?
        enableNushellIntegration = false;
        flags = [ "--disable-up-arrow" ];
        settings = {
          enter_accept = true;
          inline_height = 20;
          search_mode = "prefix";
          show_preview = false;
          sync.records = true;
          key_path = config.age.secrets.atuin-key.path;
        };
      };
    }
  ];
}
