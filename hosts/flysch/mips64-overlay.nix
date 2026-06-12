{
  disabledModules = [
    ../../modules/common/neovim.nix
    # run0-sudo-shim has no mips64 package
    ../../modules/linux/run0.nix
    # jj fork pulls serde_bser which doesn't build under bytes 1.x
    ../../modules/common/jujutsu.nix

    # flysch is a headless build runner — no shell history sync, dev git config,
    # or backups, which also keeps those secrets out of its agenix set. atuin is
    # two modules (the linux one consumes the secret the common one declares), so
    # both go.
    ../../modules/common/atuin/default.nix
    ../../modules/linux/atuin.nix
    ../../modules/common/git.nix
    ../../modules/linux/server/restic/default.nix
  ];
}
