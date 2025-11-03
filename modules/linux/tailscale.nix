{ lib, ... }:
let
  inherit (lib) enabled;

  # Shorter is better for networking interfaces IMO.
  interface = "ts0";
in
{
  services.tailscale = enabled {
    interfaceName = interface;
    useRoutingFeatures = "both";
  };

  networking.firewall.trustedInterfaces = [ interface ];
}
