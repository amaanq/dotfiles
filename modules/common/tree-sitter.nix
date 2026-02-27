{ pkgs, ... }:
let
  tree-sitter = pkgs.tree-sitter.overrideAttrs (old: rec {
    version = "0.26.6";
    src = pkgs.fetchFromGitHub {
      owner = "tree-sitter";
      repo = "tree-sitter";
      tag = "v${version}";
      hash = "sha256-ZtzwhEmNZg5brghKNiTRZSmY8FwQeWcemY2blq9j2GM=";
      fetchSubmodules = true;
    };
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-u6RmwNR4QVwyuij5RlHTLC5lNNQpWMVrlQwfwF78pYc=";
    };
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.libclang ];
    env = (old.env or { }) // {
      LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.stdenv.cc.libc.dev}/include";
    };
    patches = [ ];
  });
in
{
  environment.shellAliases = {
    ts = "tree-sitter";
    tsa = "tree-sitter-alpha";
    tss = "tree-sitter-stable";
  };
  environment.systemPackages = [
    tree-sitter
    pkgs.python313Packages.pytest
  ];
}
