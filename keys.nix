let
  keys = {
    derecho = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP contact@amaanq.com";
    scarp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6yxUX+iFXkz0+mKgiQd6IxvVQL/F84hY6lcLR7es6x contact@amaanq.com";
    nunatak = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlVwKSR+3tH54heLLH6GmDZW9JGVaUbm5a2k1WN1KN7 nunatak@libg.so";
  };
in
keys
// {
  admins = [ keys.derecho ];
  all = builtins.attrValues keys;
}
