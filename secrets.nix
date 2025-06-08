let
  inherit (import ./keys.nix) nixbox admins all;
in
{
  # nixbox server
  "hosts/nixbox/id.age".publicKeys = [ nixbox ] ++ admins;
  "hosts/nixbox/password.age".publicKeys = [ nixbox ] ++ admins;

  # nixmain desktop
  "hosts/nixmain/id.age".publicKeys = admins;
  "hosts/nixmain/password.age".publicKeys = admins;

  # shared
  "modules/common/atuin/key.age".publicKeys = admins;
  "modules/common/ssh/config.age".publicKeys = all;
}
