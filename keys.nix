let
  keys = {
    nixmain = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP amaanq12@gmail.com";
    nixbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6yxUX+iFXkz0+mKgiQd6IxvVQL/F84hY6lcLR7es6x amaanq12@gmail.com";
    nixovh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlVwKSR+3tH54heLLH6GmDZW9JGVaUbm5a2k1WN1KN7 ovh@libg.so";
  };
in
keys
// {
  admins = [ keys.nixmain ];
  adminsOvh = [ keys.nixovh ];
  all = builtins.attrValues keys;
}
