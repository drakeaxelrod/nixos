# KDE Plasma configuration using plasma-manager
{ config, pkgs, inputs, lib, colors, ... }:

{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./fonts.nix
    ./gtk.nix
    ./qt.nix
    ./theme  # OneDark Pro the me
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

      # Theme - OneDark Pro
      lookAndFeel = "org.kde.onedarkpro.desktop";
      iconTheme = "Papirus-Dark";
      theme = "breeze-dark";
      colorScheme = "OneDarkPro";

      # Cursor
      cursor = {
        theme = "Bibata-Modern-Ice";
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
        # Window decoration - Breeze with OneDark Pro style
        "org.kde.kdecoration2" = {
          "BorderSize" = "None";
          "BorderSizeAuto" = false;
          "ButtonsOnLeft" = "";
          "ButtonsOnRight" = "IAX";
          "library" = "org.kde.breeze";
          "theme" = "Breeze";
        };
      };

      # Breeze window decoration settings
      "breezerc" = {
        "Common" = {
          "OutlineCloseButton" = true;
        };
        "Windeco" = {
          "TitleAlignment" = "AlignHCenter";
          "DrawBorderOnMaximizedWindows" = false;
          "DrawSizeGrip" = false;
          "DrawTitleBarSeparator" = false;
        };
      };

      # KDE global settings
      "kdeglobals" = {
        "General" = {
          "ColorScheme" = "OneDarkPro";
          "Name" = "One Dark Pro";
        };
        "KDE" = {
          "contrast" = 4;
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
        floating = true;
        widgets = [
          # Panel Colorizer - Theme colors from lib/colors.nix
          # Note: Using settings.General for direct config since Panel Colorizer v2
          # uses complex globalSettings JSON that overrides simple options
          {
            name = "luisbocanegra.panel.colorizer";
            config = {
              General = {
                isEnabled = true;
                hideWidget = true;

                # Hide original panel background
                hideRealPanelBg = true;

                # Panel custom background
                panelBgEnabled = true;
                panelBgColorMode = 0;  # 0 = custom
                panelBgColor = colors.hex.bg0;  # Main background
                panelBgOpacity = 0.85;
                panelBgRadius = 12;

                # Panel outline
                panelOutlineColorMode = 0;
                panelOutlineColor = colors.hex.bg3;  # Border color
                panelOutlineOpacity = 0.5;
                panelOutlineWidth = 1;

                # Panel shadow
                panelShadowColor = "#000000";
                panelShadowSize = 8;
                panelShadowX = 0;
                panelShadowY = 2;

                # Text and icons
                fgColorEnabled = true;
                fgColorMode = 0;  # 0 = custom
                fgSingleColor = colors.hex.fg1;  # Normal text

                # Widget backgrounds disabled
                widgetBgEnabled = false;
              };
            };
          }
          {
            kickoff = {
              icon = "${inputs.self}/assets/icons/nix-snowflake-onedarkpro.svg";
              sortAlphabetically = false;
              compactDisplayStyle = false;
              favoritesDisplayMode = "grid";
              applicationsDisplayMode = "list";
              showButtonsFor = "powerAndSession";
              showActionButtonCaptions = false;
              pin = false;
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
          "org.kde.plasma.panelspacer" # Left spacer - pushes center content
          # Plasmusic Toolbar - centered in panel
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
          "org.kde.plasma.panelspacer" # Right spacer - keeps center content centered
          # Pager - after center section
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
                position = "adaptive"; # adaptive, besideTime, belowTime
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
                # bold = true;
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

    # Good Linux Applications
    vlc
    spotify


    # Panel customization
    plasma-panel-colorizer

    # Cursor theme
    bibata-cursors

    # Icon theme
    papirus-icon-theme
    papirus-folders

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

}
