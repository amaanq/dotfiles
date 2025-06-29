let
  keys = {
    nixmain = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP amaanq12@gmail.com";
    nixbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6yxUX+iFXkz0+mKgiQd6IxvVQL/F84hY6lcLR7es6x amaanq12@gmail.com";
  };
in
keys
// {
  admins = [ keys.nixmain ];
  all = builtins.attrValues keys;
}
