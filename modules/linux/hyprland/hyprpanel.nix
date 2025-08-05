{
  config,
  lib,
  ...
}:
let
  inherit (lib) merge mkIf enabled;
in
# Disabled in favor of QuickShell
{ }
