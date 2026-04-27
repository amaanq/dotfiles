{ lib, ... }:
let
  inherit (lib.lists) singleton;
in
{
  # Point the system resolver at hickory-dns on loopback (configured in
  # hickory-dns.nix) so DoH/DoQ to NextDNS is used for every lookup.
  networking.dns = singleton "::1";

  networking.knownNetworkServices = [
    "Thunderbolt Bridge"
    "Wi-Fi"
  ];
}
