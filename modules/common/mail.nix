{ lib, ... }:
let
  inherit (lib) mkConst;
in
{
  options.mail = {
    amaanq = {
      ipv4 = mkConst "152.53.83.122";
      ipv6 = mkConst "2a0a:4cc0:2000:3f59::1";
    };

    rampart = {
      ipv4 = mkConst "152.53.31.156";
      zone = mkConst "rampart.email";

      # stalwart's authserv-id, compared verbatim by rampart's reply policy.
      mx = mkConst "mx.rampart.email";
    };
  };
}
