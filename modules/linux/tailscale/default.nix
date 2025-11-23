{
  self,
  config,
  lib,
  ...
}:
let
  inherit (lib) enabled;

  # Shorter is better for networking interfaces IMO.
  interface = "ts0";
in
{
  secrets.tailscaleAuthKey.file = ./authkey.age;

  services.tailscale = enabled {
    interfaceName = interface;
    useRoutingFeatures = "both";
    authKeyFile = config.secrets.tailscaleAuthKey.path;
    extraUpFlags = [ "--login-server=https://headscale.${self.scarp.networking.domain}" ];
  };

  networking.firewall.trustedInterfaces = [ interface ];
}
