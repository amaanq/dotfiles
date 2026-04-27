{
  self,
  config,
  pkgs,
  keys,
  lib,
  age-plugin-fido2-hmac,
  ...
}:
let
  inherit (lib) enabled;
in
{
  age.tombkey = enabled {
    userFlake = self;
    masterIdentities = [
      { identity = self + "/secrets/iray-37504518.pub"; }
      { identity = self + "/secrets/roa-37504840.pub"; }
      { identity = self + "/secrets/telo-37504930.pub"; }
      { identity = self + "/secrets/efatra-37605510.pub"; }
      { identity = self + "/secrets/dimy-37605531.pub"; }
      { identity = self + "/secrets/enina-37605687.pub"; }
    ];
    hostPubkey = keys.${config.networking.hostName} or keys.derecho;
    agePlugins = lib.optionals (age-plugin-fido2-hmac.packages ? ${pkgs.stdenv.hostPlatform.system}) [
      age-plugin-fido2-hmac.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
