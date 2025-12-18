{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf (config.isDesktop && !config.isLaptop) {
  services.ollama = enabled {
    host = "127.0.0.1";
    port = 11434;
    loadModels = [ "nomic-embed-text" ];
  };

  environment.systemPackages = [
    pkgs.ollama
  ];
}
