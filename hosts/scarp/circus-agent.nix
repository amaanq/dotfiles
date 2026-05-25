{
  self,
  config,
  lib,
  ...
}:
let
  inherit (lib) enabled remove;
in
{
  imports = [ (self + /modules/services/circus-agent-client.nix) ];

  # XXX: scarp is RAM-constrained for now, so give it half the jobs and disable big-parallel
  # until I buy more RAM.
  services.circusAgentClient = enabled {
    maxJobs = config.builderMaxJobs / 2;
    supportedFeatures = remove "big-parallel" config.nix.settings.system-features;
  };
}
