inputs: self: super:
let
  inherit (self)
    attrValues
    filter
    getAttrFromPath
    hasAttrByPath
    collectNix
    ;

  modulesCommon = collectNix ../modules/common;
  modulesLinux = collectNix ../modules/linux;
  modulesDarwin = collectNix ../modules/darwin;

  collectInputs =
    let
      inputs' = attrValues inputs;
    in
    path: inputs' |> filter (hasAttrByPath path) |> map (getAttrFromPath path);

  inputModulesLinux = collectInputs [
    "nixosModules"
    "default"
  ];
  inputModulesDarwin = collectInputs [
    "darwinModules"
    "default"
  ];

  specialArgs = inputs // {
    inherit inputs;

    keys = import ../keys.nix;
    lib = self;
  };
in
{
  nixosSystem' =
    module:
    super.nixosSystem {
      inherit specialArgs;

      modules = [
        module
        inputs.nix-wrappers.nixosModules.system-wrappers
      ]
      ++ modulesCommon
      ++ modulesLinux
      ++ inputModulesLinux;
    };

  darwinSystem' =
    module:
    super.darwinSystem {
      inherit specialArgs;

      modules = [
        module
      ]
      ++ modulesCommon
      ++ modulesDarwin
      ++ inputModulesDarwin;
    };
}
