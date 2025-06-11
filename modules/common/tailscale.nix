{ config, lib, ... }:
let
  inherit (lib) optionalString;
in
{
  environment.shellAliases.tsl = "${optionalString config.isLinux "sudo "}tailscale";
}
