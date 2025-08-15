{ config, lib, ... }:
let
  inherit (lib) enabled;
  user = "amaanq";
in
{
  age.secrets.atuin-key = {
    file = ./key.age;
    owner = user;
  };

  home-manager.users.${user} = {
    programs.atuin = enabled {
      daemon = enabled {
        logLevel = "error";
      };

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
  };
}
