{
  config,
  lib,
  pkgs,
  inputs,
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
    BROWSER = "thorium";
  };

  environment.systemPackages =
    optional config.isLinux (
      pkgs.symlinkJoin {
        name = "thorium";
        paths = [ inputs.thorium.packages.${pkgs.system}.thorium-avx2 ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/thorium \
            --add-flags "--use-angle=vulkan"
        '';
      }
    )
    ++ optional config.isDarwin inputs.thorium.packages.${pkgs.system}.thorium-arm;
}
