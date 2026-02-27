{
  lib,
  opencode,
  pkgs,
  ...
}:
let
  bun_1_3_10 = pkgs.bun.overrideAttrs (_: {
    version = "1.3.10";
    src = pkgs.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.10/bun-linux-x64.zip";
      hash = "sha256-9XvAGH45Yj3nFro6OJ/aVIay175xMamAulTce3M9Lgg=";
    };
  });

  opencodePkgs = pkgs.extend (
    _: prev: {
      bun = bun_1_3_10;
    }
  );

  opencode' =
    (opencodePkgs.callPackage "${opencode}/nix/opencode.nix" {
      node_modules = opencodePkgs.callPackage "${opencode}/nix/node_modules.nix" {
        rev = opencode.shortRev or opencode.dirtyShortRev or "dirty";
      };
    }).overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ ../opencode-usage.patch ];
      });

  opencodeConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    theme = "system";
    instructions = [ "~/.config/claude/CLAUDE.md" ];
    mcp = {
      github = {
        type = "remote";
        url = "https://api.githubcopilot.com/mcp/insiders";
        oauth = false;
        headers = {
          Authorization = "Bearer {env:GH_TOKEN}";
        };
      };
      chrome-devtools = {
        type = "local";
        command = [
          "chrome-devtools-mcp"
          "--browser-url"
          "http://127.0.0.1:9222"
        ];
      };
      ida-pro-mcp = {
        type = "local";
        command = [
          "/home/amaanq/projects/coc2/.venv/bin/python3"
          "/home/amaanq/projects/coc2/.venv/lib/python3.14/site-packages/ida_pro_mcp/server.py"
          "--ida-rpc"
          "http://127.0.0.1:13337"
        ];
        enabled = false; # Only enable when IDA Pro RPC is running
      };
    };
    command = {
      humanizer = {
        description = "Remove AI writing patterns from text";
        template = "Use the humanizer skill to review and rewrite $ARGUMENTS to sound more natural and human-written. Remove AI patterns like inflated symbolism, promotional language, em dash overuse, rule of three, and AI vocabulary words.";
      };
      claudeception = {
        description = "Extract reusable skills from this session";
        template = "Use the claudeception skill to review this session. Identify any non-obvious solutions, debugging techniques, or patterns worth preserving as reusable skills.";
      };
      napkin = {
        description = "Update the repo napkin with session learnings";
        template = "Use the napkin skill. Read .claude/napkin.md, apply what's there, and update it with anything learned during this session.";
      };
      apk-analysis = {
        description = "Analyze a decompiled Android APK for API endpoints";
        template = "Use the android-apk-api-analysis skill to analyze $ARGUMENTS. Discover API endpoints, authentication flows, and assess replication feasibility.";
      };
      fix-extension-update = {
        description = "Fix stuck Chromium extension updates";
        template = "Use the chromium-extension-update-stuck skill to diagnose and fix the extension update issue. $ARGUMENTS";
      };
      twitter-graphql-debug = {
        description = "Debug Twitter/X GraphQL API issues";
        template = "Use the twitter-graphql-query-id-debugging skill to debug the GraphQL API issue. $ARGUMENTS";
      };
    };
  };
in
{
  environment.etc."opencode/opencode.json".text = opencodeConfig;

  environment.variables.OPENCODE_CONFIG = "/etc/opencode/opencode.json";

  environment.shellAliases = {
    oc = "opencode";
  };

  environment.systemPackages = [
    opencode'
  ];
}
