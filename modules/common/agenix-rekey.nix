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
    ];
    storageMode = "local";
    localStorageDir = self + "/hosts/${config.networking.hostName}/secrets";
    hostPubkey = keys.${config.networking.hostName} or keys.derecho;
  };
}
