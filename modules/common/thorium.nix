{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    attrValues
    merge
    mkIf
    optionalAttrs
    ;
in
merge
<| mkIf config.isDesktop {
  environment.variables = {
    BROWSER = "thorium";
  };

  environment.systemPackages =
    attrValues
    <|
      optionalAttrs config.isLinux {
        thorium = pkgs.symlinkJoin {
          name = "thorium";
          paths = [ inputs.thorium.packages.${pkgs.system}.thorium-avx2 ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/thorium \
              --add-flags "--use-angle=vulkan"
          '';
        };
      }
      // optionalAttrs config.isDarwin {
        inherit (inputs.thorium.packages.${pkgs.system}) thorium-arm;
      };
}
