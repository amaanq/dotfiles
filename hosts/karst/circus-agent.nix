{ self, lib, ... }:
let
  inherit (lib) enabled;
in
{
  imports = [ (self + /modules/services/circus-agent-client.nix) ];

  services.circusAgentClient = enabled;
}
