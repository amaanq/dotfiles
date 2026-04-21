# Tarn-specific module gating on top of the shared cross-ppc64-fixes.
# The overlay body itself lives in modules/linux/cross-ppc64-fixes.nix.
{ lib, ... }:
{
  # Modules disabled for ppc64 cross-compilation. Most of the previously
  # disabled set was either removed upstream from the closure or now gates
  # itself on isDesktop — try them in this build and trim further if any
  # individual cross-build fails.
  #
  # kept ENABLED on ppc64 (agenix secrets now rekeyed for tarn):
  #   common/agenix.nix        — secrets alias
  #   common/git.nix           — user config + rekeyed secrets.gitPrivate/gitIdentity
  #   common/nix.nix           — experimental-features + builderKey/githubToken
  #   common/shell/aliases.nix — secrets.openai/glm
  #   common/ssh/default.nix   — secrets.sshConfig
  #   linux/tailscale/default.nix — restored once authkey decryption confirmed
  #   common/shell/nushell.nix — restored (prior cross issues w/ atuin/carapace re-tested)
  #   common/jujutsu.nix       — restored (signing block self-gates on isDesktop)
  #   linux/run0.nix           — restored (polkit body self-gates on isDesktop)
  #   common/atuin/default.nix + linux/atuin.nix — restored
  #   acme/default.nix         — restored (cert issuance via Cloudflare)
  #   linux/server/restic/default.nix — restored (no-op: only backs up if hostName == "nunatak")
  disabledModules = [
    ../../modules/common/neovim.nix
    # run0-sudo-shim flake input has no powerpc64-linux package
    ../../modules/linux/run0.nix
    # jj fork pulls serde_bser (watchman) which calls bytes::put_i16_be —
    # not in bytes 1.x's BufMut API. Disable until jj-src fork drops watchman
    # for cross or we override the serde_bser dep.
    ../../modules/common/jujutsu.nix
  ];
}
