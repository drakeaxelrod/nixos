# Home Manager configuration for draxel
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Core modules (always imported)
    ../../../modules/home/core

    # Program modules
    ../../../modules/home/programs/shell
    ../../../modules/home/programs/editors
    ../../../modules/home/programs/desktop
    ../../../modules/home/programs/desktop/ble-lock-session.nix

    # User-specific configs
    ./git.nix
  ];

  home.username = "draxel";
  home.homeDirectory = "/home/draxel";
  home.stateVersion = "25.11";

  # ==========================================================================
  # User Packages
  # ==========================================================================

  home.packages = with pkgs; [
    # CLI tools
    btop             # System monitor
    ncdu             # Disk usage analyzer
    tldr             # Simplified man pages
    httpie           # HTTP client
    dust             # Disk usage
    procs            # Process viewer
    sd               # sed alternative
    hyperfine        # Benchmarking
    tokei            # Code statistics

    # Development
    docker-compose

    # Browser
    brave

    # Media
    vlc
    spotify

    # Communication
    discord
  ];

  # ==========================================================================
  # Session Variables
  # ==========================================================================

  home.sessionVariables = {
    BROWSER = "brave";
    TERMINAL = "gnome-terminal";

    # Wayland
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";

    # Nix
    NIX_AUTO_RUN = "1";
  };

  # ==========================================================================
  # Activation Scripts
  # ==========================================================================

  home.activation = {
    # Create Projects directory if it doesn't exist
    createProjectsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/Projects
    '';
  };

  # ==========================================================================
  # Looking Glass Configuration
  # ==========================================================================
  # Optimized for AMD GPU stability with 5120x1440@240Hz ultrawide

  # Looking Glass config - comments must be on their own lines in ini files
  xdg.configFile."looking-glass/client.ini".text = ''
    [app]
    shmFile=/dev/shm/looking-glass

    [win]
    quickSplash=yes
    autoScreensaver=yes
    fullScreen=yes
    borderless=yes
    keepAspect=yes

    [input]
    captureOnFocus=yes
    grabKeyboard=no
    ignoreWindowsKeys=yes
    rawMouse=yes
    escapeKey=KEY_SCROLLLOCK

    [spice]
    host=127.0.0.1
    port=5900
    alwaysShowCursor=yes

    [audio]
    micDefault=allow

    [egl]
    ; vsync=yes prevents GPU ring timeouts on AMD
    vsync=yes
    doubleBuffer=yes
    multisample=yes
    nvGainMax=1
    nvGain=0
    scale=0
    debug=no
    noBufferAge=no
    noSwapDamage=no
    scalePointer=yes

    [opengl]
    mipmap=yes
    ; vsync=yes for AMD GPU stability
    vsync=yes
    ; preventBuffer=no prevents ring timeouts on AMD
    preventBuffer=no
    ; amdPinnedMem=no prevents GPU hangs
    amdPinnedMem=no

    [wayland]
    warpSupport=yes
    fractionScale=yes
  '';

  # ==========================================================================
  # BLE Lock Session - Auto lock/unlock via Bluetooth proximity
  # ==========================================================================
  # Find your phone's address with: ble-lock-session --scan

  services.ble-lock-session = {
    enable = false;
    targetAddress = "44:C6:3C:4B:24:4C";
    lockCommand = "loginctl lock-session";
    unlockCommand = "loginctl unlock-session";
    checkInterval = 5;  # Seconds between checks
    timeout = 5;        # Bluetooth ping timeout
    rssiThreshold = -70;  # Adjust: -50 (close), -70 (room), -80 (far)
  };
}
