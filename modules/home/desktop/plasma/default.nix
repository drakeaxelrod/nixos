# KDE Plasma configuration using plasma-manager
{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./fonts.nix
    ./gtk.nix
    ./qt.nix
  ];

  # Examples:
  # https://github.com/nix-community/plasma-manager/blob/trunk/examples/home.nix
  # How to get current settings:
  # nix run github:nix-community/plasma-manager > $HOME/.config/nixos/modules/home/desktop/plasma/current-settings.refence.nix


  # Plasma Manager configuration
  # NOTE: plasma-manager only configures user-level settings (home-manager)
  # System-level Plasma must be enabled in host config: modules.desktop.plasma.enable = true
  programs.plasma = {
    enable = true;

    # Workspace settings
    workspace = {
      clickItemTo = "select";

      # Theme
      lookAndFeel = "org.kde.breezedark.desktop";
      iconTheme = "Papirus-Dark";
      theme = "breeze-dark";
      colorScheme = "BreezeDark";

      # Cursor
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };

      # Wallpaper
      wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/nix-wallpaper-binary-red_8k.png";
    };


    # Shortcuts
    shortcuts = {
      ksmserver = {
        "Lock Session" = [
          "Screensaver"
          "Meta+Ctrl+Alt+L"
        ];
      };

      kwin = {
        "Expose" = "Meta+,";
        "Switch Window Down" = "Meta+J";
        "Switch Window Left" = "Meta+H";
        "Switch Window Right" = "Meta+L";
        "Switch Window Up" = "Meta+K";
        "Window Close" = "Meta+Q";
        # "Window Maximize" = "Meta+Up";
        # "Window Minimize" = "Meta+Down";
        # "Switch to Desktop 1" = "Meta+1";
        # "Switch to Desktop 2" = "Meta+2";
        # "Switch to Desktop 3" = "Meta+3";
        # "Switch to Desktop 4" = "Meta+4";
        # "Window to Desktop 1" = "Meta+Shift+1";
        # "Window to Desktop 2" = "Meta+Shift+2";
        # "Window to Desktop 3" = "Meta+Shift+3";
        # "Window to Desktop 4" = "Meta+Shift+4";
      };

      # "org.kde.konsole.desktop" = {
      #   "_launch" = "Meta+Return";
      # };

      # "org.kde.dolphin.desktop" = {
      #   "_launch" = "Meta+E";
      # };
    };

    # Hot corners
    hotkeys = {
      commands = {
        # Add custom hotkeys here
        "launch-konsole" = {
          name = "Launch Konsole";
          key = "Meta+Return";
          command = "konsole";
        };
        "launch-dolphin" = {
          name = "Launch Dolphin";
          key = "Meta+E";
          command = "dolphin";
        };
      };
    };

    # Desktop configuration
    configFile = {
      # KWin (window manager)
      "kwinrc" = {
        "Desktops" = {
          "Number" = 4;
          "Rows" = 1;
        };
        "Windows" = {
          "FocusPolicy" = "FocusFollowsMouse";
          "NextFocusPrefersMouse" = true;
        };
        "Effect-overview" = {
          "BorderActivate" = 9;  # Top-left corner
        };
      };

      # Dolphin (file manager)
      "dolphinrc" = {
        "General" = {
          "ShowFullPath" = true;
          "ShowHiddenFiles" = true;
        };
        "CompactMode" = {
          "FontWeight" = 400;
        };
      };

      # Konsole (terminal)
      "konsolerc" = {
        "Desktop Entry" = {
          "DefaultProfile" = "OneDarkPro.profile";
        };
      };
    };

    # Panels configuration
    panels = [
      {
        location = "bottom";
        height = 44;
        widgets = [
          {
            name = "org.kde.plasma.kickoff";
            config = {
              General = {
                icon = "nix-snowflake";
                favoritesDisplayMode = "grid";
                applicationsDisplayMode = "list";
                showButtonsFor = [
                  "lock-screen"
                  "logout"
                  "save-session"
                  "switch-user"
                  "suspend"
                  "hibernate"
                  "reboot"
                  "shutdown"
                ];
                showActionButtonCaptions = false;
                popupHeight = 500;
                popupWidth = 700;
              };
            };
          }
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General = {
                launchers = [
                  # "applications:kdesystemsettings.desktop"
                  # "applications:org.kde.dolphin.desktop"
                  # "applications:zen-beta.desktop"
                  # "applications:org.kde.konsole.desktop"
                  # "applications:code.desktop"
                  # "applications:virt-manager.desktop"
                ];
              };
            };
          }
          "org.kde.plasma.marginsseparator" # Spacer
          # "org.kde.plasma.pager"
          {
            name = "org.kde.plasma.pager";
            config = {
              General = {
                showWindowOutlines = true;
                showApplicationIconsOnWindowOutlines = true;
                showOnlyCurrentScreen = true;
                navigationWrapsAround = false;
                displayedText = "Number"; # Options: None, Number, Name

                selectingCurrentVirtualDesktop = "doNothing"; # Options: doNothing, showDesktop
              };
            };
          }
          {
            plasmusicToolbar = {
              panelIcon = {
                icon = "view-media-track";
                albumCover = {
                  useAsIcon = false;
                  radius = 8;
                };
              };
              playbackSource = "auto";
              musicControls = {
                showPlaybackControls = true;
                volumeStep = 5;
              };
              songText = {
                maximumWidth = 200;
                scrolling = {
                  enable = true;
                  behavior = "alwaysScrollExceptOnHover";
                  speed = 3;
                };
              };
            };
          }
          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.volume"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.battery"
              ];
              hidden = [
                "org.kde.plasma.clipboard"
              ];
            };
          }
          {
            digitalClock = {
              date = {
                enable = true;
                format = { custom = "ddd d MMM"; };  # e.g., "Fri 3 Jan"
                position = "besideTime";
              };
              time = {
                format = "24h";
                showSeconds = "never";
              };
              calendar = {
                firstDayOfWeek = "monday";
                showWeekNumbers = true;
              };
              timeZone = {
                selected = [ "Local" ];
                changeOnScroll = false;
                format = "city";
                alwaysShow = false;
              };
              font = {
                family = "Inter";
                bold = true;
                size = 12;
              };
            };
          }
        ];
      }
    ];
  };

  # Additional KDE packages
  home.packages = with pkgs; [
    # KDE applications
    kdePackages.kate
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.gwenview
    kdePackages.okular
    kdePackages.spectacle
    kdePackages.kcalc
    kdePackages.filelight
    kdePackages.partitionmanager

    # Cursor theme
    bibata-cursors

    # helpful
    unrar
    p7zip
  ];

  # Set Bibata cursor theme for all applications
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Konsole One Dark Pro profile
  xdg.dataFile."konsole/OneDarkPro.profile".text = ''
    [Appearance]
    ColorScheme=OneDarkPro
    Font=Lilex Nerd Font,10,-1,5,50,0,0,0,0,0

    [General]
    Name=OneDarkPro
    Parent=FALLBACK/

    [Interaction Options]
    # Enable semantic shell integration (OSC 133)
    # Allows: click on command output, scroll between prompts
    SemanticInputClick=true
    SemanticUpDown=true

    [Scrolling]
    ScrollBarPosition=2
    HistoryMode=2
  '';

  # Konsole One Dark Pro color scheme
  xdg.dataFile."konsole/OneDarkPro.colorscheme".text = ''
    [Background]
    Color=40,44,52

    [BackgroundIntense]
    Color=40,44,52

    [Foreground]
    Color=171,178,191

    [ForegroundIntense]
    Color=171,178,191

    [Color0]
    Color=40,44,52

    [Color0Intense]
    Color=92,99,112

    [Color1]
    Color=224,108,117

    [Color1Intense]
    Color=224,108,117

    [Color2]
    Color=152,195,121

    [Color2Intense]
    Color=152,195,121

    [Color3]
    Color=229,192,123

    [Color3Intense]
    Color=229,192,123

    [Color4]
    Color=97,175,239

    [Color4Intense]
    Color=97,175,239

    [Color5]
    Color=198,120,221

    [Color5Intense]
    Color=198,120,221

    [Color6]
    Color=86,182,194

    [Color6Intense]
    Color=86,182,194

    [Color7]
    Color=171,178,191

    [Color7Intense]
    Color=255,255,255

    [General]
    Description=One Dark Pro
    Opacity=1
    Wallpaper=
  '';
}
