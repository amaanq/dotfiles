{
  config,
  lib,
  ...
}:
let
  isTile = config.nixpkgs.hostPlatform.isTile or false;
in
{
  config = lib.mkIf isTile {
    nixpkgs.config.allowUnsupportedSystem = true;

    # The stub dynamic linker (for foreign non-Nix binaries) is built with
    # pkgsStatic = musl, which has no TILE-Gx port. It is irrelevant on a tilegx
    # appliance, so drop it rather than drag in a musl toolchain that cannot build.
    environment.stub-ld.enable = lib.mkForce false;

    nixpkgs.overlays = [
      (
        final: _prev:
        let
          # Go has no TILE-Gx backend and never will, so buildGoModule gets
          # GOARCH=null and every Go package throws at eval. Stub the builders to
          # an empty (but overrideAttrs-able, pname/meta-carrying) derivation so
          # the closure evaluates; Go tools are simply absent on tilegx.
          goStub =
            args:
            final.runCommandLocal (args.pname or args.name or "go-stub-tilegx") {
              pname = args.pname or "go-stub";
              version = args.version or "0";
              meta = (args.meta or { }) // {
                broken = false;
              };
            } "mkdir -p $out/bin";
        in
        {
          buildGoModule = goStub;
          buildGoPackage = goStub;
        }
      )
    ];
  };
}
