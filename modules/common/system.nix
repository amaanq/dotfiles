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
    hostSystem = mkConst config.nixpkgs.hostPlatform.system;
    os = mkConst <| last <| splitString "-" config.nixpkgs.hostPlatform.system;

    type = mkValue "desktop";

    isLinux = mkConst <| config.os == "linux";
    isDarwin = mkConst <| config.os == "darwin";

    isDesktop = mkConst <| config.type == "desktop";
    isServer = mkConst <| config.type == "server";

    cpuArch = mkValue null;

    isLaptop = mkValue false;
    isVirtual = mkValue false;

    isBuilder = mkValue false;
    builderSpeedFactor = mkValue 1;
    builderMaxJobs = mkValue 8;

    displayOutputs = mkValue { };
  };
}
