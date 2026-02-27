inputs: self: super:
let
  inherit (self)
    attrValues
    filter
    getAttrFromPath
    hasAttrByPath
    hasInfix
    collectNix
    ;

  excludeRoleDirs = paths: filter (p: !(hasInfix "/desktop/" (toString p)) && !(hasInfix "/server/" (toString p))) paths;

  modulesCommon = collectNix ../modules/common |> excludeRoleDirs;
  modulesCommonDesktop = collectNix ../modules/common/desktop;
  modulesLinux = collectNix ../modules/linux |> excludeRoleDirs;
  modulesLinuxDesktop = collectNix ../modules/linux/desktop;
  modulesLinuxServer = collectNix ../modules/linux/server;
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
    type: module:
    super.nixosSystem {
      inherit specialArgs;

      modules = [
        module
        inputs.nix-wrappers.nixosModules.system-wrappers
      ]
      ++ modulesCommon
      ++ modulesLinux
      ++ (
        if type == "desktop" then
          modulesLinuxDesktop ++ modulesCommonDesktop
        else if type == "server" then
          modulesLinuxServer
        else
          [ ]
      )
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
      ++ modulesCommonDesktop
      ++ modulesDarwin
      ++ inputModulesDarwin;
    };
}
