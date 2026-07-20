{ lib, ... }:
let
  inherit (lib) mkConst;
in
{
  options.mail = {
    hostName = mkConst "mail.amaanq.com";

    domains = mkConst [
      "amaanq.com"
      "ameerq.com"
      "libg.so"
      "hkpoolservices.com"
    ];

    amaanq = {
      ipv4 = mkConst "152.53.83.122";
      ipv6 = mkConst "2a0a:4cc0:2000:3f59::1";
    };

    rampart = {
      ipv4 = mkConst "152.53.31.156";
      zone = mkConst "rampart.email";
      mx = mkConst "mx.rampart.email";
    };
  };
}
