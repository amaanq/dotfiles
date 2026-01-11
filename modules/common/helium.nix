{
  config,
  lib,
  pkgs,
  helium,
  ...
}:
let
  inherit (lib)
    merge
    mkIf
    optional
    ;
in
merge
<| mkIf config.isDesktop {
  environment.variables = {
    BROWSER = "helium";
  };

  environment.systemPackages =
    optional config.isLinux (
      pkgs.symlinkJoin {
        name = "helium";
        paths = [ helium.packages.${config.hostSystem}.helium ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/helium \
            --add-flags "--use-angle=vulkan --enable-quic --quic-version=h3-29"
        '';
      }
    )
    ++ optional config.isDarwin helium.packages.${config.hostSystem}.helium;
}
