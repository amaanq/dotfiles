{ config, pkgs, ... }:
{
  age.secrets.atuin-key = {
    file = ./key.age;
    owner = "amaanq";
  };

  environment.systemPackages = [ pkgs.atuin ];

  environment.variables.ATUIN_CONFIG_DIR = "/etc/atuin";
}
