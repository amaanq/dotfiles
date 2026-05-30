{
  disabledModules = [
    ../../modules/common/neovim.nix
    # run0-sudo-shim has no powerpc64-linux package
    ../../modules/linux/run0.nix
    # jj fork pulls serde_bser which doesn't build under bytes 1.x
    ../../modules/common/jujutsu.nix
  ];
}
