{
  lib,
  ...
}:
let
  inherit (lib) enabled;
in
{
  services.keyd = enabled {
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock = "overload(control, esc)";
      };
    };
  };
}
