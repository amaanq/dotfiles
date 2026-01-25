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
    filterAttrs
    hasPrefix
    ;

  users =
    config.users.users
    |> filterAttrs (_: u: u.home != null && hasPrefix "/Users/" u.home)
    |> attrValues;

  shadowScript = pkgs.writeScript "shadow-xcode.nu" ''
    use std null_device

    let shadow_path = $"($env.HOME)/.local/shadow"
    let original_size = ls "/usr/bin/SplitForks" | get 0.size

    let shadoweds = ls /usr/bin
    | flatten
    | where {
      # All xcode-select binaries are the same size, so we can narrow down and not run weird stuff.
      $in.size == $original_size and (try {
        open $null_device | ^$in.name out+err>| str contains "xcode-select: note: No developer tools were found, requesting install."
      } catch {
        # If it exited with a nonzero code, it's probably already set up.
        false
      })
    }
    | get name
    | each { path basename }

    rm -rf $shadow_path
    mkdir $shadow_path

    for shadowed in $shadoweds {
      ln --symbolic /usr/bin/false ($shadow_path | path join $shadowed)
    }
  '';
in
{
  # Run shadow script for each configured user on activation
  # -H sets HOME to the target user's home directory
  system.activationScripts.postActivation.text = users |> concatMapStringsSep "\n" (u: ''
    sudo -H -u ${u.name} ${pkgs.nushell}/bin/nu ${shadowScript} || true
  '');
}
