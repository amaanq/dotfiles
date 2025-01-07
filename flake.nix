{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
    let username = "amaan.qureshi"; in
    let configuration = { pkgs, ... }: {
      imports = [
        home-manager.darwinModules.home-manager
      ];

      nix.gc.automatic = true;

      nix.optimise.automatic = true;

      users = {
        knownUsers = [ username ];
        users.${username} = {
          home = "/Users/${username}";
          shell = "${pkgs.nushell}/bin/nu";
          uid = 502;
        };
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = {
          home.stateVersion = "24.11";
          home.packages = [
            pkgs.alt-tab-macos
            pkgs.aria2
            pkgs.awscli
            pkgs.aws-vault
            pkgs.bat
            pkgs.bazelisk
            pkgs.bear
            pkgs.binutils
            pkgs.bottom
            pkgs.cmake
            pkgs.codeql
            pkgs.coreutils
            pkgs.cpufetch
            pkgs.cpuinfo
            pkgs.curl
            pkgs.delta
            pkgs.difftastic
            pkgs.docker
            pkgs.fastfetch
            pkgs.fd
            pkgs.flock
            pkgs.fzf
            pkgs.gh
            pkgs.ghc
            pkgs.git
            pkgs.gitui
            pkgs.gnumake
            pkgs.gnupg
            pkgs.go
            pkgs.google-cloud-sdk
            pkgs.gperftools
            pkgs.graphviz
            pkgs.grpcurl
            pkgs.hidden-bar
            pkgs.htop
            pkgs.hub
            pkgs.iina
            pkgs.jankyborders
            pkgs.jdk
            pkgs.jujutsu
            pkgs.just
            pkgs.jq
            pkgs.keychain
            pkgs.kubectx
            # pkgs.kubernetes
            pkgs.kubernetes-helm
            pkgs.lazydocker
            pkgs.maccy
            pkgs.maven
            pkgs.mutagen
            pkgs.ncdu
            pkgs.nodejs
            pkgs.nushell
            pkgs.onefetch
            pkgs.pcre2
            # pkgs.pinentry
            pkgs.pkgconf
            pkgs.pnpm
            pkgs.podman
            pkgs.procs
            pkgs.pyenv
            pkgs.radare2
            pkgs.rbenv
            pkgs.ripgrep
            pkgs.skhd
            pkgs.spotifyd
            pkgs.starship
            pkgs.time
            pkgs.tokei
            pkgs.topgrade
            pkgs.unzip
            pkgs.upx
            pkgs.vault
            pkgs.viu
            pkgs.volta
            pkgs.wasmtime
            pkgs.watchman
            pkgs.wget
            pkgs.yabai
            pkgs.yq
            pkgs.zig
            pkgs.zoxide
          ];
        };
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs = {
        config.allowUnfree = true;
        hostPlatform = "aarch64-darwin";
      };
    };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."amaan-ddog" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
