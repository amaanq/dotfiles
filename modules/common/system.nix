{ config, lib, ... }:
let
  inherit (lib)
    last
    mkConst
    mkValue
    splitString
    ;
in
{
  options = {
    os = mkConst <| last <| splitString "-" config.nixpkgs.hostPlatform.system;

    type = mkValue "desktop";

    isLinux = mkConst <| config.os == "linux";
    isDarwin = mkConst <| config.os == "darwin";

    isDesktop = mkConst <| config.type == "desktop";
    isServer = mkConst <| config.type == "server";

    isVirtual = mkValue false;

    isBuilder = mkValue false;
  };
}
