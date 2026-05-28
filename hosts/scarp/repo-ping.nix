{ config, pkgs, ... }:
let
  watchList = [
    "jj-vcs/jj"
    "LordGrimmauld/run0-sudo-shim"
    "thunderbird/thunderbird-android"
    "SchildiChat/schildichat-android-next"
    "SchildiChat/matrix-rust-components-kotlin"
    "SchildiChat/matrix-rust-sdk"
  ];

  configFile = pkgs.writeText "repo-ping-config.json" (builtins.toJSON { watch = watchList; });

  script =
    pkgs.writeText "repo-ping.nu" # nu
      ''
        def main [] {
          let webhook = (open --raw $env.REPO_PING_WEBHOOK_FILE | str trim)
          let watch = (open $env.REPO_PING_CONFIG | get watch)
          let state_path = $env.REPO_PING_STATE
          let initial_state = if ($state_path | path exists) { open $state_path } else { {} }

          let final_state = $watch | reduce --fold $initial_state {|repo, state|
            let last = $state | get -i $repo
            let new_sha = try {
              let commits = (http get --headers {Accept: 'application/vnd.github+json'} $'https://api.github.com/repos/($repo)/commits?per_page=20')
              let new_commits = if ($last == null) {
                $commits | first 1
              } else {
                $commits | take while {|c| $c.sha != $last } | first 10
              }
              if (($new_commits | length) > 0) {
                let ordered = ($new_commits | reverse)
                let newest = ($ordered | last)
                let n = ($ordered | length)
                let count_label = if ($n == 1) { '1 new commit' } else { $'($n) new commits' }
                let compare_url = if ($last == null) { $newest.html_url } else { $'https://github.com/($repo)/compare/($last)...($newest.sha)' }
                let lines = ($ordered | each {|c|
                  let short = ($c.sha | str substring 0..<7)
                  let firstline = ($c.commit.message | lines | first | str substring 0..<72)
                  let name = ($c.commit.author.name | str substring 0..<60)
                  $'[`($short)`](($c.html_url)) ($firstline) - ($name)'
                })
                let raw_desc = ($lines | str join "\n")
                let description = if (($raw_desc | str length) > 4000) {
                  let head = ($lines | first 5 | str join "\n")
                  let omitted = (($lines | length) - 5)
                  $"($head)\n… and ($omitted) more"
                } else {
                  $raw_desc
                }
                let gh_user = $newest.author?
                let author_block = if ($gh_user != null) {
                  { name: ($gh_user.login | str substring 0..<80), icon_url: $gh_user.avatar_url, url: $gh_user.html_url }
                } else {
                  { name: ($newest.commit.author.name | str substring 0..<80) }
                }
                let embed = {
                  title: $'[($repo)] ($count_label)'
                  url: $compare_url
                  description: $description
                  color: 0x7289da
                  author: $author_block
                  timestamp: $newest.commit.author.date
                }
                http post --content-type application/json $webhook { embeds: [$embed] }
              }
              if (($commits | length) > 0) { $commits | first | get sha } else { null }
            } catch {|err|
              print -e $'repo-ping: ($repo) failed: ($err.msg)'
              null
            }
            if ($new_sha != null) { $state | upsert $repo $new_sha } else { $state }
          }

          $final_state | save -f $state_path
        }
      '';
in
{
  secrets.repoPingWebhook = {
    rekeyFile = ./repo-ping-webhook.age;
    owner = "repo-ping";
  };

  users.users.repo-ping = {
    isSystemUser = true;
    group = "repo-ping";
  };
  users.groups.repo-ping = { };

  systemd.services.repo-ping = {
    description = "Poll GitHub repos and post pushes to Discord";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "repo-ping";
      Group = "repo-ping";
      StateDirectory = "repo-ping";
      StateDirectoryMode = "0700";
      Environment = [
        "REPO_PING_WEBHOOK_FILE=${config.secrets.repoPingWebhook.path}"
        "REPO_PING_CONFIG=${configFile}"
        "REPO_PING_STATE=/var/lib/repo-ping/state.nuon"
      ];
      ExecStart = "${pkgs.nushell}/bin/nu -n ${script}";
    };
  };

  systemd.timers.repo-ping = {
    description = "Poll repo-ping every 10 min";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "10m";
      Unit = "repo-ping.service";
      Persistent = true;
    };
  };
}
