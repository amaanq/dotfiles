let
  keys = {
    derecho = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+36H8eD4p4waEpgPejhPCNGymi+OSN9fZ5LRUBcOnP contact@amaanq.com";
    karst = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGYffnfHaDR5SIm/zEzou1uW1ncdB5F+k4XOuLBqWTrT root@karst";
    loess = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSFz+It9kIrNHbquRwFvm4Ou6sSejU9jfOHZTnNH7bF root@loess";
    moraine = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICRnTMcNNbv8pHgDIcQD+1zDj0X1xCPRewdk+fLtdu+ root@moraine";
    nunatak = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADunPFxQt/gB9duWXHX6dsI4+muz85egvnrLIWUyS+o root@nunatak";
    yardang = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQQBN06V58ll+e2+t4X9qq/foFY+Hsx9DVQtEoGKz+R root@yardang";
    guyot = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDw+hVS37i7wciA2D6UeBbQFNjUmYpSC90aDdcqPKp9W root@guyot";
    scarp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpGaxgsOi5dIbFMVqA90Gy5tvhLNn4ggLDdnPl3KuW3 root@scarp";
    simoom = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF2VD1i3vLpEmlN1nYMSn4KyxKf7nt/ekP3+YGxH772I contact@amaanq.com";
    tarn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJh1jaHd93hodjkXjKCQ2dMlfxMUg7mi758Y6iVubPaP root@tarn";
    varve = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDePnpqjL94IYg724wrlvkghw0/dMEiaWAsuVNlMPdwD root@varve";
  };
  yubikeys = {
    iray-37504518 = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJfPMiKZ+NvPZb8j3EhzGd5ebjRHcXGo5rNZY1u64mzQAAAAD3NzaDphbWFhbnEtaXJheQ== contact@amaanq.com";
    roa-37504840 = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAjYeEYU1IfZkoVBYzEqEgzYqlh70cneFvOWnZXsfjaiAAAADnNzaDphbWFhbnEtcm9h contact@amaanq.com";
    telo-37504930 = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO+wUGlqBGzUfWFkfnyTfZNbcO5LUJrCQry4bj+80YpsAAAAD3NzaDphbWFhbnEtdGVsbw== contact@amaanq.com";
    efatra-37605510 = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAICBt95vmXS9TSis070JWq8mTPVfOTlxKzKKei9dATnCHAAAAEXNzaDphbWFhbnEtZWZhdHJh contact@amaanq.com";
    dimy-37605531 = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIND4w+ET8r7I20z3VodCfQwlFyTfBgDuJGmpVngWxRUoAAAAD3NzaDphbWFhbnEtZGlteQ== contact@amaanq.com";
    enina-37605687 = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILZX27u7CtjraFy2Ad8zvoCclCWx1QY9zrimL+DNUlRvAAAAEHNzaDphbWFhbnEtZW5pbmE= contact@amaanq.com";
    fito = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHWmTxhci2aWb0ijG65eLJ9lb9qbvz2fr3jdUoxgtKUEAAAAD3NzaDphbWFhbnEtZml0bw== contact@amaanq.com";
  };
  builder = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOW26rsiPa44dsoItJtB+Ngt7VeW702CDQR+3fYMkcQk nix-builder";

  inherit (builtins) attrValues;
in
keys
// yubikeys
// {
  inherit builder yubikeys;
  admins = [
    keys.derecho
    keys.simoom
  ]
  ++ attrValues yubikeys;
  all = attrValues keys ++ attrValues yubikeys ++ [ builder ];
}
