# OneDark Pro Theme for KDE Plasma
# Includes color scheme, Konsole theme, Kvantum theme, icons, and cursor
{ config, lib, pkgs, ... }:

let
  # Custom Papirus with OneDark Pro cyan folders
  papirus-onedarkpro = pkgs.stdenvNoCC.mkDerivation {
    pname = "papirus-icon-theme-onedarkpro";
    version = pkgs.papirus-icon-theme.version;

    src = pkgs.papirus-icon-theme;

    nativeBuildInputs = [ pkgs.papirus-folders ];

    installPhase = ''
      mkdir -p $out/share/icons
      cp -r $src/share/icons/Papirus-Dark $out/share/icons/Papirus-OneDarkPro

      # Use cyan as the base (closest to OneDark blue #61afef)
      papirus-folders -t Papirus-OneDarkPro -o -C cyan --theme-dir $out/share/icons

      # Update theme name in index.theme
      sed -i 's/Name=Papirus-Dark/Name=Papirus OneDark Pro/' $out/share/icons/Papirus-OneDarkPro/index.theme
      sed -i 's/Inherits=Papirus/Inherits=Papirus-Dark/' $out/share/icons/Papirus-OneDarkPro/index.theme
    '';
  };

  # Custom Bibata cursor based on Modern-Ice (white cursor with dark outline)
  # Fits well with dark themes like OneDark Pro
  bibata-onedarkpro = pkgs.stdenvNoCC.mkDerivation {
    pname = "bibata-cursors-onedarkpro";
    version = pkgs.bibata-cursors.version;

    src = pkgs.bibata-cursors;

    installPhase = ''
      mkdir -p $out/share/icons
      cp -r $src/share/icons/Bibata-Modern-Ice $out/share/icons/Bibata-OneDarkPro

      # Update cursor theme name
      sed -i 's/Name=Bibata-Modern-Ice/Name=Bibata OneDark Pro/' $out/share/icons/Bibata-OneDarkPro/index.theme
      sed -i 's/Comment=.*/Comment=Bibata cursor theme for OneDark Pro/' $out/share/icons/Bibata-OneDarkPro/index.theme
    '';
  };
in
{
  # Install custom icon and cursor themes
  home.packages = [
    papirus-onedarkpro
    bibata-onedarkpro
  ];
  # Install the OneDark Pro color scheme
  xdg.dataFile."color-schemes/OneDarkPro.colors".source = ./OneDarkPro.colors;

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

  # Konsole OneDark Pro color scheme
  xdg.dataFile."konsole/OneDarkPro.colorscheme".text = ''
    [Background]
    Color=22,25,29

    [BackgroundIntense]
    Color=30,34,39

    [Foreground]
    Color=171,178,191

    [ForegroundIntense]
    Color=215,218,224

    [Color0]
    Color=63,68,81

    [Color0Intense]
    Color=79,86,102

    [Color1]
    Color=224,85,97

    [Color1Intense]
    Color=255,97,110

    [Color2]
    Color=140,194,101

    [Color2Intense]
    Color=165,224,117

    [Color3]
    Color=209,143,82

    [Color3Intense]
    Color=240,164,93

    [Color4]
    Color=74,165,240

    [Color4Intense]
    Color=77,196,255

    [Color5]
    Color=193,98,222

    [Color5Intense]
    Color=222,115,255

    [Color6]
    Color=66,179,194

    [Color6Intense]
    Color=76,209,224

    [Color7]
    Color=215,218,224

    [Color7Intense]
    Color=230,230,230

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
