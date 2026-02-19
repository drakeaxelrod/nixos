# Ollama - Local LLM server
# Runs LLMs locally for AI-assisted development
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.services.ollama;

  # Use base ollama package - it auto-detects CUDA/ROCm at runtime
  # This avoids expensive recompilation and uses binary cache
  ollamaPackage = pkgs.ollama;
in
{
  options.modules.services.ollama = {
    enable = lib.mkEnableOption "Ollama local LLM server";

    acceleration = lib.mkOption {
      type = lib.types.enum [ "cuda" "rocm" "cpu" ];
      default = "cpu";
      description = "GPU acceleration backend (cuda for NVIDIA, rocm for AMD, cpu for no GPU)";
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "llama3.2" ];
      description = "Models to pull on activation";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind to";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Port to listen on";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for Ollama port";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = ollamaPackage;
      host = cfg.host;
      port = cfg.port;
      openFirewall = cfg.openFirewall;
    };

    # Pull models on activation
    system.activationScripts.ollama-models = lib.mkIf (cfg.models != []) {
      text = ''
        # Pull models in background after boot
        (
          # Wait for ollama service to be ready
          sleep 10
          for model in ${lib.concatStringsSep " " cfg.models}; do
            ${ollamaPackage}/bin/ollama pull "$model" 2>/dev/null || true
          done
        ) &
      '';
    };

    # Add ollama CLI to system packages
    environment.systemPackages = [ ollamaPackage ];
  };
}
