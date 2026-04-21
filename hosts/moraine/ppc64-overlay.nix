# Moraine-specific module gating on top of the shared cross-ppc64-fixes.
# The overlay body itself lives in modules/linux/cross-ppc64-fixes.nix.
{ ... }:
{
  # Disable modules that reference flake packages not available for powerpc64-linux
  disabledModules = [
    ../../modules/linux/run0.nix
    ../../modules/common/neovim.nix
    ../../modules/common/jujutsu.nix
    ../../modules/common/claude-code/default.nix
    # kept ENABLED on ppc64 (agenix secrets now rekeyed for tarn):
    #   common/agenix.nix  — secrets alias
    #   common/git.nix     — user config + rekeyed secrets.gitPrivate/gitIdentity
    #   common/nix.nix     — experimental-features from flake nixConfig + secrets.builderKey/githubToken
    #   common/shell/aliases.nix — secrets.openai/glm
    #   common/ssh/default.nix   — secrets.sshConfig
    ../../modules/linux/server/restic/default.nix
    ../../modules/linux/tailscale/default.nix
    ../../modules/common/shell/nushell.nix
    ../../modules/common/atuin/default.nix
    ../../modules/linux/atuin.nix
    ../../modules/acme/default.nix
    ../../modules/common/yazi.nix
    ../../modules/linux/desktop/nix-ld.nix
  ];
}
