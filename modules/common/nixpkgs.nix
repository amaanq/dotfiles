{ lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      formats = prev.formats // {
        toml =
          args:
          (prev.formats.toml args)
          // {
            generate =
              name: value:
              final.runCommand name {
                nativeBuildInputs = [ final.buildPackages.nushell ];
                value = builtins.toJSON value;
                passAsFile = [ "value" ];
                preferLocalBuild = true;
              } ''nu -c "open --raw '$valuePath' | from json | to toml" > $out'';
          };
      };
    })
  ]
  # Nuking perl in its entirety.
  ++ [
    (
      final: prev:
      {
        # git-repo's wrapper pulls the full perl-enabled git.
        git-repo = prev.git-repo.override { git = final.gitMinimal; };

        # in aspell, bin/aspell-import is a perl script which imports
        # ispell wordlists. This is not used in KDE
        aspell = prev.aspell.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            rm -f $out/bin/aspell-import
          '';
        });

        # Patch kio-extras at the kdePackages *scope* level so Dolphin
        # et al. rebuild against the perl-free variant.
        kdePackages = prev.kdePackages.overrideScope (
          kfinal: kprev: {
            kio-extras = kprev.kio-extras.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace CMakeLists.txt \
                  --replace-fail 'add_subdirectory( info )' \
                                 '# add_subdirectory( info )  # perl-free closure'
              '';
            });
          }
        );
      }
      // lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
        xdg-utils = final.symlinkJoin {
          name = "xdg-utils-handlr-shim-${prev.handlr-regex.version or "0"}";
          paths = [
            final.xdg-user-dirs
            (final.writeShellScriptBin "xdg-open" ''exec ${final.handlr-regex}/bin/handlr open "$@"'')
            (final.writeShellScriptBin "xdg-mime" ''exec ${final.handlr-regex}/bin/handlr mime "$@"'')
            (final.writeShellScriptBin "xdg-settings" ''exec ${final.handlr-regex}/bin/handlr get "$@"'')
            (final.writeShellScriptBin "xdg-email" ''exec ${final.handlr-regex}/bin/handlr open "mailto:$*"'')

            # These are install-time helpers that are not used on NixOS.
            (final.writeShellScriptBin "xdg-desktop-menu" "exit 0")
            (final.writeShellScriptBin "xdg-desktop-icon" "exit 0")
            (final.writeShellScriptBin "xdg-icon-resource" "exit 0")
            (final.writeShellScriptBin "xdg-screensaver" "exit 0")
          ];
          meta = {
            description = "xdg-utils shim backed by handlr-regex (perl-free)";
            mainProgram = "xdg-open";
          };
        };

        # winetricks's wrapper embeds perl in PATH for a handful of niche
        # verbs (mostly font/registry helpers). Scrub the store ref so perl
        # drops out of the closure; if a verb that needs perl is invoked,
        # it'll just error at runtime. This should *probably* be fine.
        winetricks = prev.winetricks.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.removeReferencesTo ];
          postFixup = (old.postFixup or "") + ''
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
      }
    )
  ];
}
