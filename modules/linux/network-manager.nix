{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    const
    enabled
    filterAttrs
    getAttr
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  networking.networkmanager = enabled {
    # lmfao https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/1603
    # we need to clear interface DNS after NM configures it
    # so that DHCP/RA DNS isn't used by systemd-resolved
    dispatcherScripts = [
      {
        source = pkgs.writeText "clear-interface-dns" ''
          #!/bin/sh
          # Skip Tailscale (ts0)
          if [ "$DEVICE_IFACE" != "ts0" ]; then
            if [ "$2" = "up" ] || [ "$2" = "dhcp4-change" ] || [ "$2" = "dhcp6-change" ]; then
              ${pkgs.systemd}/bin/resolvectl dns "$DEVICE_IFACE" "" || true
            fi
          fi
        '';
        type = "basic";
      }
    ];
  };

  users.extraGroups.networkmanager.members =
    config.users.users |> filterAttrs (const <| getAttr "isNormalUser") |> attrNames;

  environment.shellAliases.wifi = "nmcli dev wifi show-password";
}
