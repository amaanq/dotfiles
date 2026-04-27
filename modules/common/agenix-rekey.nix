{
  self,
  config,
  keys,
  ...
}:
{
  age.rekey = {
    masterIdentities = [
      {
        identity = "/home/amaanq/.ssh/id";
        pubkey = keys.derecho;
      }
      { identity = self + "/secrets/iray-37504518.pub"; }
      { identity = self + "/secrets/roa-37504840.pub"; }
      { identity = self + "/secrets/telo-37504930.pub"; }
      { identity = self + "/secrets/efatra-37605510.pub"; }
      { identity = self + "/secrets/dimy-37605531.pub"; }
      { identity = self + "/secrets/enina-37605687.pub"; }
    ];
    storageMode = "local";
    localStorageDir = self + "/hosts/${config.networking.hostName}/secrets";
    hostPubkey = keys.${config.networking.hostName} or keys.derecho;
  };
}
