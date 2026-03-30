let
  keys = {
    derecho = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP contact@amaanq.com";
    karst = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGYffnfHaDR5SIm/zEzou1uW1ncdB5F+k4XOuLBqWTrT root@karst";
    loess = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSFz+It9kIrNHbquRwFvm4Ou6sSejU9jfOHZTnNH7bF root@loess";
    nunatak = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADunPFxQt/gB9duWXHX6dsI4+muz85egvnrLIWUyS+o root@nunatak";
    scarp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpGaxgsOi5dIbFMVqA90Gy5tvhLNn4ggLDdnPl3KuW3 root@scarp";
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
