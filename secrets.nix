let
  inherit (import ./keys.nix) nixbox admins all;
in
{
  # nixbox server
  "hosts/nixbox/id.age".publicKeys = [ nixbox ] ++ admins;
  "hosts/nixbox/password.age".publicKeys = [ nixbox ] ++ admins;

  # shared
  "modules/common/ssh/config.age".publicKeys = all;
}
