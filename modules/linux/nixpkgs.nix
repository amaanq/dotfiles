{ xdg-utils-nu, ... }:
{
  nixpkgs.overlays = [
    (_: prev: { xdg-utils = xdg-utils-nu.packages.${prev.stdenv.hostPlatform.system}.xdg-utils-nu; })
    (_final: prev: {
      bcachefs-tools = prev.bcachefs-tools.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/bcachefs-tools-codegen-skip-fvisibility.patch
          ./patches/bcachefs-tools-codegen-host-linker.patch
        ];
      });
    })
    # The linux half of the perl purge
    (final: prev: {
      # winetricks's wrapper embeds perl in PATH for a handful of niche
      # verbs
      winetricks = prev.winetricks.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.removeReferencesTo ];
        postFixup = (old.postFixup or "") + /* sh */ ''
          remove-references-to -t ${final.perl} $out/bin/winetricks $out/bin/.winetricks-wrapped
        '';
      });

      # libvirt defaults to enabling Xen on x86_64 Linux, dragging in
      # xen → ipxe → syslinux → perl. We only use the qemu/KVM driver,
      # so Xen can be dropped.
      libvirt = prev.libvirt.override { enableXen = false; };

      # rnnoise-plugin drags webkitgtk_4_1 into buildInputs purely because
      # JUCE's default plugin profile includes a WebBrowser module. The
      # built shared object has no UI, so we strip webkit and tell JUCE
      # to skip web.
      rnnoise-plugin = prev.rnnoise-plugin.overrideAttrs (old: {
        buildInputs = builtins.filter (p: (p.pname or "") != "webkitgtk") (old.buildInputs or [ ]);
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DJUCE_WEB_BROWSER=0" ];
      });

      # plausible's BEAM stack pulls erlang → wxwidgets → webkitgtk for the
      # Observer GUI, which is useless on a headless server and parks 100MB+
      # of GTK in the closure.
      plausible = prev.plausible.override {
        beam27Packages = prev.beamMinimal27Packages;
      };

      radicle-node = prev.radicle-node.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace \
            crates/radicle-node/src/test/node.rs \
            crates/radicle-cli/tests/commands/id.rs \
            crates/radicle-cli/tests/commands/cob.rs \
            --replace-fail 'Duration::from_secs(6)' 'Duration::from_secs(60)'
        '';
        checkFlags = (old.checkFlags or [ ]) ++ [ "--test-threads=1" ];
      });
    })
  ];
}
