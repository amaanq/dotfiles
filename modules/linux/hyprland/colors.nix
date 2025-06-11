{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    rosePineColors = mkOption {
      type = types.attrs;
      default = {
        base = "191724";
        surface = "1f1d2e";
        overlay = "26233a";
        muted = "6e6a86";
        subtle = "908caa";
        text = "e0def4";
        love = "eb6f92";
        gold = "f6c177";
        rose = "ebbcba";
        pine = "31748f";
        foam = "9ccfd8";
        iris = "c4a7e7";
        highlightLow = "21202e";
        highlightMed = "403d52";
        highlightHigh = "524f67";
      };
      description = "Rose Pine color scheme for Hyprland";
    };
  };

  config = { };
}
