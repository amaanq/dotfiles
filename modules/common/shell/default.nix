{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMapStringsSep
    concatStringsSep
    filterAttrs
    getExe
    hasPrefix
    mapAttrsToList
    merge
    mkIf
    ;

  users =
    config.users.users
    |> filterAttrs (_: u: u.home != null && hasPrefix "/Users/" u.home)
    |> attrValues;

  # Generate .zshrc that exports env vars and execs nushell
  zshrc = pkgs.writeText "zshrc" ''
    # Export environment variables
    ${
      config.environment.variables
      |> mapAttrsToList (name: value: "export ${name}='${value}'")
      |> concatStringsSep "\n"
    }

    # Exec nushell
    SHELL='${getExe pkgs.nushell}' exec "$SHELL"
  '';
in
merge {
  environment.shells = [ pkgs.nushell ];

  environment.systemPackages = [
    pkgs.nu_scripts # Nushell scripts and completions.
  ];
}
<| mkIf config.isDarwin {
  environment.systemPackages = [ pkgs.nushell ];
  # Create .zshrc for each configured user on Darwin
  system.activationScripts.postActivation.text =
    users |> concatMapStringsSep "\n" (u: "cp ${zshrc} ${u.home}/.zshrc");
}
