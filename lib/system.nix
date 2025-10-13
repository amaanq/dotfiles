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

  # Stylix and Niri's nixos module handles home-manager integration automatically
  inputHomeModulesLinux =
    attrValues (
      builtins.removeAttrs inputs [
        "stylix"
        "niri"
      ]
    )
    |> filter (hasAttrByPath [
      "homeModules"
      "default"
    ])
    |> map (getAttrFromPath [
      "homeModules"
      "default"
    ]);

  inputHomeModulesDarwin =
    attrValues (
      builtins.removeAttrs inputs [
        "stylix"
        "niri"
        "nirinit"
        "buckMaterialShell"
      ]
    )
    |> filter (hasAttrByPath [
      "homeModules"
      "default"
    ])
    |> map (getAttrFromPath [
      "homeModules"
      "default"
    ]);

  inputModulesLinux = collectInputs [
    "nixosModules"
    "default"
  ];
  inputModulesDarwin = collectInputs [
    "darwinModules"
    "default"
  ];

  inputOverlays = collectInputs [
    "overlays"
    "default"
  ];
  overlayModule = {
    nixpkgs.overlays = inputOverlays;
  };

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
        overlayModule

        {
          home-manager.sharedModules = inputHomeModulesLinux;
        }
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
        overlayModule

        {
          home-manager.sharedModules = inputHomeModulesDarwin;
        }
      ]
      ++ modulesCommon
      ++ modulesDarwin
      ++ inputModulesDarwin;
    };
}
