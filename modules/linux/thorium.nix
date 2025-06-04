# Thorium with GPU-accelration working on Wayland
{
  pkgs,
  inputs,
  ...
}:
{
  environment.variables = {
    BROWSER = "thorium";
  };

  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "thorium";
      paths = [ inputs.thorium.packages.${pkgs.system}.thorium-avx2 ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/thorium \
          --add-flags "--use-angle=vulkan"
      '';
    })
  ];
}
