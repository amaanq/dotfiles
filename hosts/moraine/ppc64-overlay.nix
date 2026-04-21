# Moraine-specific module gating on top of the shared cross-ppc64-fixes.
# The overlay body itself lives in modules/linux/cross-ppc64-fixes.nix.
{ ... }:
{
  disabledModules = [
    ../../modules/common/neovim.nix
    # run0-sudo-shim has no powerpc64-linux package
    ../../modules/linux/run0.nix
    # jj fork pulls serde_bser which doesn't build under bytes 1.x
    ../../modules/common/jujutsu.nix
  ];
}
