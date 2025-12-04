{ keys, ... }:
{
  users.users.build = {
    description = "Distributed Build User";
    isNormalUser = true;
    openssh.authorizedKeys.keys = keys.all;
    group = "build";
  };

  users.groups.build = { };

  nix.settings.trusted-users = [ "build" ];
}
