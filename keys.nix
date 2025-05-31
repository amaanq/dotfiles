let
  keys = {
    nixmain = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP amaanq12@gmail.com";
    agenix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG18Qy3Jsw1+A7Utz9y3oK3aB9+/RwSSsNey7QicQPAk agenix@nixmain";
  };
in
keys
// {
  admins = [ keys.nixmain ];
  all = builtins.attrValues keys;
}
