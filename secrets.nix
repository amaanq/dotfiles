let
  inherit (import ./keys.nix) all;
in
{
  # shared
  "modules/common/ssh/config.age".publicKeys = all;
  "modules/common/gpg/private-key.age".publicKeys = all;
}
