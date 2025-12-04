let
  keys = {
    derecho = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP contact@amaanq.com";
    nunatak = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlVwKSR+3tH54heLLH6GmDZW9JGVaUbm5a2k1WN1KN7 nunatak@libg.so";
    scarp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6yxUX+iFXkz0+mKgiQd6IxvVQL/F84hY6lcLR7es6x contact@amaanq.com";
    simoom = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF2VD1i3vLpEmlN1nYMSn4KyxKf7nt/ekP3+YGxH772I contact@amaanq.com";
  };
  builder = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOW26rsiPa44dsoItJtB+Ngt7VeW702CDQR+3fYMkcQk nix-builder";
in
keys
// {
  inherit builder;
  admins = [
    keys.derecho
    keys.simoom
  ];
  all = builtins.attrValues keys ++ [ builder ];
}
