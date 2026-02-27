{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  services.prometheus.exporters.node = enabled {
    enabledCollectors = [
      "processes"
      "systemd"
    ];
    listenAddress = "[::]";
  };
}
