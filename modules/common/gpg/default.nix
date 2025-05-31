{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  secrets.gpgPrivateKey = {
    file = ./private-key.age;
    mode = "400";
    owner = config.users.users.amaanq.name or "amaanq";
  };

  programs.gnupg.agent.enable = true;
  environment.systemPackages = [ pkgs.gnupg ];

  home-manager.sharedModules = [
    {
      programs.gpg = enabled {
        settings = {
          default-key = "FCC13F47A6900D64239FF13BE67890ADC4227273";
          keyserver = "hkps://keys.openpgp.org";
          auto-key-retrieve = true;
        };
      };
    }
  ];
}
