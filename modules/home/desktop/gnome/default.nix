# GNOME user configuration (home-manager)
# NOTE: This only configures user-level GNOME settings (dconf, user packages)
# System-level GNOME must be enabled in host config: modules.desktop.gnome.enable = true
{ config, pkgs, lib, ... }:

{
  imports = [
    ./fonts.nix
    ./gtk.nix
    ./qt.nix
  ];

  dconf.settings = {
    # Wallpaper
    "org/gnome/desktop/background" = {
      picture-uri = "file://${config.home.homeDirectory}/Pictures/wallpapers/nix-wallpaper-binary-red_8k.png";
      picture-uri-dark = "file://${config.home.homeDirectory}/Pictures/wallpapers/nix-wallpaper-binary-red_8k.png";
      picture-options = "zoom";
      primary-color = "#000000";
      secondary-color = "#000000";
    };

    # Interface
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-show-weekday = true;
      clock-show-seconds = false;
      font-name = "Inter 11";
      document-font-name = "Inter 11";
      monospace-font-name = "Lilex Nerd Font Propo 10";
      cursor-theme = lib.mkForce "Bibata-Modern-Classic";  # Override GTK default
      overlay-scrolling = false;  # Disable overlay scrollbars globally
    };

    # Window management
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      focus-mode = "click";
      resize-with-right-button = true;
    };


    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      maximize = [ "<Super>Up" ];
      minimize = [ "<Super>Down" ];
      move-to-workspace-1 = [ "<Shift><Super>1" ];
      move-to-workspace-2 = [ "<Shift><Super>2" ];
      move-to-workspace-3 = [ "<Shift><Super>3" ];
      move-to-workspace-4 = [ "<Shift><Super>4" ];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
    };

    # Shell - Favorite apps in dock
    # To find desktop entry names (after nx switch):
    #   ls ~/.nix-profile/share/applications/
    #   ls /run/current-system/sw/share/applications/
    # Common names: discord.desktop, steam.desktop, code.desktop, etc.
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Settings.desktop"
        "org.gnome.Nautilus.desktop"
        "virt-manager.desktop"
        # "code.desktop"
        # "discord.desktop"
        # "zen-browser.desktop"
        "org.gnome.Terminal.desktop"
      ];
      disable-user-extensions = false;
    };

    # Touchpad
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      natural-scroll = true;
    };

    # Mouse
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";  # No acceleration for gaming
    };

    # Power
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      power-button-action = "interactive";
    };

    # Night light
    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = false;
      night-light-temperature = lib.hm.gvariant.mkUint32 3500;
      night-light-schedule-automatic = true;
    };

    # Privacy
    "org/gnome/desktop/privacy" = {
      remember-recent-files = true;
      recent-files-max-age = 30;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
      old-files-age = lib.hm.gvariant.mkUint32 7;
    };

    # Custom keybindings
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "gnome-terminal";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>e";
      command = "nautilus";
      name = "Files";
    };

    # Nautilus
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      show-hidden-files = true;
    };

    "org/gnome/nautilus/list-view" = {
      default-zoom-level = "small";
      use-tree-view = true;
    };

    # Mutter
    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      edge-tiling = true;
      workspaces-only-on-primary = true;
    };

    # GNOME Terminal
    "org/gnome/terminal/legacy" = {
      theme-variant = "dark";
      default-show-menubar = false;
    };

    "org/gnome/terminal/legacy/profiles:" = {
      default = "b1dcc9dd-5262-4d8d-a863-c897e6d979b9";
      list = [ "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" ];
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      visible-name = "One Dark Pro";
      use-system-font = false;
      font = "Lilex Nerd Font 10";
      use-theme-colors = false;
      # One Dark Pro colors
      foreground-color = "#abb2bf";
      background-color = "#282c34";
      bold-color = "#abb2bf";
      bold-color-same-as-fg = true;
      # Palette: Black, Red, Green, Yellow, Blue, Purple, Cyan, White (normal + bright)
      palette = [
        "#282c34"  # black
        "#e06c75"  # red
        "#98c379"  # green
        "#e5c07b"  # yellow
        "#61afef"  # blue
        "#c678dd"  # purple
        "#56b6c2"  # cyan
        "#abb2bf"  # white
        "#5c6370"  # bright black
        "#e06c75"  # bright red
        "#98c379"  # bright green
        "#e5c07b"  # bright yellow
        "#61afef"  # bright blue
        "#c678dd"  # bright purple
        "#56b6c2"  # bright cyan
        "#ffffff"  # bright white
      ];
      cursor-colors-set = true;
      cursor-foreground-color = "#282c34";
      cursor-background-color = "#abb2bf";
      highlight-colors-set = true;
      highlight-foreground-color = "#abb2bf";
      highlight-background-color = "#3e4451";
      audible-bell = false;
      scrollback-unlimited = true;
      show-scrollbar = false;
    };
  };

  home.packages = with pkgs; [
    gnome-tweaks
    dconf-editor
    gnome-extension-manager
    gnome-disk-utility
    gnome-terminal
    bibata-cursors
  ];

  # Set Bibata cursor theme
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Default applications
  # To find desktop file names for apps:
  #   ls ~/.nix-profile/share/applications/
  #   ls /run/current-system/sw/share/applications/
  # Or search all: find ~/.nix-profile /run/current-system/sw -name "*.desktop" | grep <app-name>
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "zen-browser.desktop";
      "x-scheme-handler/http" = "zen-browser.desktop";
      "x-scheme-handler/https" = "zen-browser.desktop";
      "x-scheme-handler/about" = "zen-browser.desktop";
      "x-scheme-handler/unknown" = "zen-browser.desktop";
    };
  };
}
