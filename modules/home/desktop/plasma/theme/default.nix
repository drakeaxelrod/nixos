# OneDark Pro Theme for KDE Plasma
# Includes color scheme, Konsole theme, Kvantum theme, icons, and cursor
# Uses centralized color palette from lib/colors.nix
{ config, lib, pkgs, colors, ... }:

{
  # Install icon and cursor themes
  home.packages = [
    pkgs.papirus-icon-theme
    pkgs.bibata-cursors
  ];

  # KDE Plasma color scheme (system-wide: notifications, dialogs, menus, etc.)
  # Generated from centralized palette
  xdg.dataFile."color-schemes/OneDarkPro.colors".text = ''
    [ColorEffects:Disabled]
    Color=56,56,56
    ColorAmount=0
    ColorEffect=0
    ContrastAmount=0.65
    ContrastEffect=1
    IntensityAmount=0.1
    IntensityEffect=2

    [ColorEffects:Inactive]
    ChangeSelectionColor=true
    Color=112,111,110
    ColorAmount=0.025
    ColorEffect=2
    ContrastAmount=0.1
    ContrastEffect=2
    Enable=false
    IntensityAmount=0
    IntensityEffect=0

    [Colors:Button]
    BackgroundAlternate=${colors.rgb.bg2}
    BackgroundNormal=${colors.rgb.bg3}
    DecorationFocus=${colors.rgb.blue}
    DecorationHover=${colors.rgb.blue}
    ForegroundActive=${colors.rgb.blue}
    ForegroundInactive=${colors.rgb.fg1}
    ForegroundLink=${colors.rgb.blue}
    ForegroundNegative=${colors.rgb.red}
    ForegroundNeutral=${colors.rgb.yellow}
    ForegroundNormal=${colors.rgb.fg2}
    ForegroundPositive=${colors.rgb.green}
    ForegroundVisited=${colors.rgb.purple}

    [Colors:Complementary]
    BackgroundAlternate=${colors.rgb.bg1}
    BackgroundNormal=${colors.rgb.bg0}
    DecorationFocus=${colors.rgb.blue}
    DecorationHover=${colors.rgb.blue}
    ForegroundActive=${colors.rgb.blue}
    ForegroundInactive=${colors.rgb.fg1}
    ForegroundLink=${colors.rgb.blue}
    ForegroundNegative=${colors.rgb.red}
    ForegroundNeutral=${colors.rgb.yellow}
    ForegroundNormal=${colors.rgb.fg2}
    ForegroundPositive=${colors.rgb.green}
    ForegroundVisited=${colors.rgb.purple}

    [Colors:Header]
    BackgroundAlternate=${colors.rgb.bg1}
    BackgroundNormal=${colors.rgb.bg0}
    DecorationFocus=${colors.rgb.blue}
    DecorationHover=${colors.rgb.blue}
    ForegroundActive=${colors.rgb.blue}
    ForegroundInactive=${colors.rgb.fg1}
    ForegroundLink=${colors.rgb.blue}
    ForegroundNegative=${colors.rgb.red}
    ForegroundNeutral=${colors.rgb.yellow}
    ForegroundNormal=${colors.rgb.fg2}
    ForegroundPositive=${colors.rgb.green}
    ForegroundVisited=${colors.rgb.purple}

    [Colors:Header][Inactive]
    BackgroundAlternate=${colors.rgb.bg1}
    BackgroundNormal=${colors.rgb.bg0}
    DecorationFocus=${colors.rgb.blue}
    DecorationHover=${colors.rgb.blue}
    ForegroundActive=${colors.rgb.blue}
    ForegroundInactive=${colors.rgb.fg0}
    ForegroundLink=${colors.rgb.blue}
    ForegroundNegative=${colors.rgb.red}
    ForegroundNeutral=${colors.rgb.yellow}
    ForegroundNormal=${colors.rgb.fg1}
    ForegroundPositive=${colors.rgb.green}
    ForegroundVisited=${colors.rgb.purple}

    [Colors:Selection]
    BackgroundAlternate=${colors.rgb.bg2}
    BackgroundNormal=${colors.rgb.blue}
    DecorationFocus=${colors.rgb.blue}
    DecorationHover=${colors.rgb.blue}
    ForegroundActive=${colors.rgb.whiteBright}
    ForegroundInactive=${colors.rgb.fg2}
    ForegroundLink=${colors.rgb.yellow}
    ForegroundNegative=${colors.rgb.red}
    ForegroundNeutral=${colors.rgb.yellow}
    ForegroundNormal=${colors.rgb.whiteBright}
    ForegroundPositive=${colors.rgb.green}
    ForegroundVisited=${colors.rgb.purple}

    [Colors:Tooltip]
    BackgroundAlternate=${colors.rgb.bg1}
    BackgroundNormal=${colors.rgb.bg1}
    DecorationFocus=${colors.rgb.blue}
    DecorationHover=${colors.rgb.blue}
    ForegroundActive=${colors.rgb.blue}
    ForegroundInactive=${colors.rgb.fg1}
    ForegroundLink=${colors.rgb.blue}
    ForegroundNegative=${colors.rgb.red}
    ForegroundNeutral=${colors.rgb.yellow}
    ForegroundNormal=${colors.rgb.fg2}
    ForegroundPositive=${colors.rgb.green}
    ForegroundVisited=${colors.rgb.purple}

    [Colors:View]
    BackgroundAlternate=${colors.rgb.bg0}
    BackgroundNormal=${colors.rgb.bg0}
    DecorationFocus=${colors.rgb.blue}
    DecorationHover=${colors.rgb.blue}
    ForegroundActive=${colors.rgb.blue}
    ForegroundInactive=${colors.rgb.fg1}
    ForegroundLink=${colors.rgb.blue}
    ForegroundNegative=${colors.rgb.red}
    ForegroundNeutral=${colors.rgb.yellow}
    ForegroundNormal=${colors.rgb.fg1}
    ForegroundPositive=${colors.rgb.green}
    ForegroundVisited=${colors.rgb.purple}

    [Colors:Window]
    BackgroundAlternate=${colors.rgb.bg1}
    BackgroundNormal=${colors.rgb.bg0}
    DecorationFocus=${colors.rgb.blue}
    DecorationHover=${colors.rgb.blue}
    ForegroundActive=${colors.rgb.blue}
    ForegroundInactive=${colors.rgb.fg1}
    ForegroundLink=${colors.rgb.blue}
    ForegroundNegative=${colors.rgb.red}
    ForegroundNeutral=${colors.rgb.yellow}
    ForegroundNormal=${colors.rgb.fg1}
    ForegroundPositive=${colors.rgb.green}
    ForegroundVisited=${colors.rgb.purple}

    [General]
    ColorScheme=OneDarkPro
    Name=One Dark Pro
    TintFactor=0
    accentActiveTitlebar=false
    accentInactiveTitlebar=false
    shadeSortColumn=true

    [KDE]
    contrast=4

    [WM]
    activeBackground=${colors.rgb.bg0}
    activeBlend=${colors.rgb.fg2}
    activeForeground=${colors.rgb.fg2}
    inactiveBackground=${colors.rgb.bg0}
    inactiveBlend=${colors.rgb.fg0}
    inactiveForeground=${colors.rgb.fg0}
  '';

  # Konsole OneDark Pro profile
  xdg.dataFile."konsole/OneDarkPro.profile".text = ''
    [Appearance]
    ColorScheme=OneDarkPro
    Font=Lilex Nerd Font,10,-1,5,50,0,0,0,0,0

    [General]
    Name=OneDarkPro
    Parent=FALLBACK/

    [Interaction Options]
    SemanticInputClick=true
    SemanticUpDown=true

    [Scrolling]
    ScrollBarPosition=2
    HistoryMode=2
  '';

  # Konsole OneDark Pro color scheme (using centralized palette RGB format)
  xdg.dataFile."konsole/OneDarkPro.colorscheme".text = ''
    [Background]
    Color=${colors.rgb.bg0}

    [BackgroundIntense]
    Color=${colors.rgb.bg1}

    [Foreground]
    Color=${colors.rgb.fg1}

    [ForegroundIntense]
    Color=${colors.rgb.fg2}

    [Color0]
    Color=${colors.rgb.black}

    [Color0Intense]
    Color=${colors.rgb.blackBright}

    [Color1]
    Color=${colors.rgb.red}

    [Color1Intense]
    Color=${colors.rgb.redBright}

    [Color2]
    Color=${colors.rgb.green}

    [Color2Intense]
    Color=${colors.rgb.greenBright}

    [Color3]
    Color=${colors.rgb.yellow}

    [Color3Intense]
    Color=${colors.rgb.yellowBright}

    [Color4]
    Color=${colors.rgb.blue}

    [Color4Intense]
    Color=${colors.rgb.blueBright}

    [Color5]
    Color=${colors.rgb.magenta}

    [Color5Intense]
    Color=${colors.rgb.purpleBright}

    [Color6]
    Color=${colors.rgb.cyan}

    [Color6Intense]
    Color=${colors.rgb.cyanBright}

    [Color7]
    Color=${colors.rgb.white}

    [Color7Intense]
    Color=${colors.rgb.whiteBright}

    [General]
    Description=One Dark Pro
    Opacity=1
    Wallpaper=
  '';

  # Kvantum theme (copy the whole directory)
  xdg.dataFile."Kvantum/OneDarkPro".source = ./kvantum;

  # Look and Feel theme (global theme)
  xdg.dataFile."plasma/look-and-feel/org.kde.onedarkpro.desktop".source = ./org.kde.onedarkpro.desktop;
}
