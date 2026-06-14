{
  lib,
  pkgs,
  voxtype,
  ...
}:
let
  inherit (lib) enabled getExe mapAttrsToList;

  voxtypePackage =
    (import "${voxtype}/nix/packages.nix" {
      inherit pkgs;
      src = voxtype;
    }).packages.onnx;
  parakeetRevision = "8f23f0c03c8761650bdb5b40aaf3e40d2c15f1ce";
  parakeetModel = pkgs.linkFarm "parakeet-tdt-0.6b-v3" (
    mapAttrsToList
      (name: hash: {
        inherit name;
        path = pkgs.fetchurl {
          url = "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx/resolve/${parakeetRevision}/${name}";
          inherit hash;
        };
      })
      {
        "encoder-model.onnx" = "sha256-mKdLIbTMABfB5wMDGaSpb0qVBuUPBwjzpRbQKnfJa7E=";
        "encoder-model.onnx.data" = "sha256-miLTcsUUVcNPE0BdolILrvtxJb0WmBOXVhQj7TLSTzY=";
        "decoder_joint-model.onnx" = "sha256-6Xjd9miFJxgsEP3i60uDBoQhZImF7yP3qGvnMr6HBsE=";
        "vocab.txt" = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
        "config.json" = "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=";
      }
  );

  alsaConfig = pkgs.writeText "voxtype-alsa.conf" ''
    <${pkgs.alsa-lib}/share/alsa/alsa.conf>

    pcm.voxtype_rnnoise {
        type pipewire
        playback_node "-1"
        capture_node "rnnoise_source"
        hint {
            show on
            description "Voxtype through RNNoise"
        }
    }
  '';

  discordMic = pkgs.writeShellApplication {
    name = "voxtype-discord-mic";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nushell
      pkgs.pipewire
      pkgs.util-linux
      pkgs.wireplumber
    ];
    text = ''
      umask 077
      runtime_dir="''${XDG_RUNTIME_DIR:?}/voxtype"
      mkdir -p "$runtime_dir"
      chmod 700 "$runtime_dir"
      exec flock "$runtime_dir/discord-mic-lock" nu ${./voxtype-discord-mic.nu} "$@"
    '';
  };

  routeFeedback = pkgs.writeShellApplication {
    name = "voxtype-route-feedback";
    runtimeInputs = [
      pkgs.nushell
      pkgs.pipewire
    ];
    text = "exec nu ${./voxtype-route-feedback.nu}";
  };

  voxtypeConfig = (pkgs.formats.toml { }).generate "voxtype-config.toml" {
    engine = "parakeet";
    state_file = "auto";

    hotkey = {
      enabled = true;
      key = "RIGHTALT";
      cancel_key = "ESC";
      mode = "toggle";
    };

    audio = {
      device = "voxtype_rnnoise";
      sample_rate = 16000;
      max_duration_secs = 120;
      feedback = {
        enabled = true;
        theme = "subtle";
        volume = 0.5;
      };
    };

    parakeet = {
      model = "${parakeetModel}";
      model_type = "tdt";
      on_demand_loading = false;
    };

    output = {
      mode = "type";
      fallback_to_clipboard = true;
      type_delay_ms = 0;
      append_text = " ";
      wait_for_modifier_release = true;
      pre_recording_command = "${getExe discordMic} mute";
      post_output_command = "${getExe discordMic} restore";
      notification = {
        on_recording_start = false;
        on_recording_stop = false;
        on_transcription = false;
      };
    };

    text = {
      spoken_punctuation = true;
      smart_auto_submit = false;
      filter_filler_words = true;
    };

    vad = {
      enabled = true;
      backend = "energy";
      threshold = 0.3;
      min_speech_duration_ms = 100;
    };
  };
in
{
  programs.voxtype = enabled {
    package = voxtypePackage;
  };

  users.users.amaanq.extraGroups = [ "input" ];

  environment.etc."voxtype/config.toml".source = voxtypeConfig;

  systemd.user.services.voxtype = {
    description = "Toggle voice typing";
    after = [
      "graphical-session.target"
      "pipewire.service"
      "pipewire-pulse.service"
    ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig.ConditionUser = "amaanq";
    serviceConfig = {
      Environment = "ALSA_CONFIG_PATH=${alsaConfig}";
      ExecStart = "${getExe voxtypePackage} daemon";
      ExecStartPost = getExe routeFeedback;
      ExecStopPost = "${getExe discordMic} restore";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
