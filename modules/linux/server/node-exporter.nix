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

  # Upstream module passes `--web.systemd-socket` but forgets `Sockets=`.
  systemd.services.prometheus-node-exporter.serviceConfig.Sockets = "prometheus-node-exporter.socket";
}
