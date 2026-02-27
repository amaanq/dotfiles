{ config, lib, ... }:
let
  inherit (lib) mkIf optionals;
in
{
  config = mkIf (config.networking.defaultGateway != null) (
    let
      inherit (config.networking.defaultGateway) interface;
    in
    {
      networking.interfaces.${interface} = {
        ipv4.addresses = optionals (config.networking.ipv4.address != null) [
          {
            inherit (config.networking.ipv4) address prefixLength;
          }
        ];

        ipv6.addresses = optionals (config.networking.ipv6.address != null) [
          {
            inherit (config.networking.ipv6) address prefixLength;
          }
        ];
      };
    }
  );
}
