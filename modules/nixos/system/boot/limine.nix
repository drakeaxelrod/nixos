# Limine - Modern, stylish bootloader with great specialisation support
#
# Boot menu format:
#   NixOS 25.05.20250115.abc1234 (Generation 42)
#   NixOS 25.05.20250115.abc1234 (Generation 42, vfio)
#
# Each entry shows: NixOS version, date, git rev, generation number,
# and specialisation tag if applicable.
#
# Theme: OneDarkPro (Atom's One Dark inspired)
# https://wiki.nixos.org/wiki/Limine
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.boot;

  # OneDarkPro color palette (without # prefix for Limine)
  colors = {
    bg = "282c34";
    fg = "abb2bf";
    black = "282c34";
    red = "e06c75";
    green = "98c379";
    yellow = "e5c07b";
    blue = "61afef";
    purple = "c678dd";
    cyan = "56b6c2";
    white = "abb2bf";
    gray = "5c6370";
    brightBlack = "5c6370";
    brightWhite = "ffffff";
    cursorline = "2d313b";
    selection = "414858";
  };
in
{
  config = lib.mkIf (cfg.loader == "limine") {
    # Boot timeout (shared across all bootloaders)
    boot.loader.timeout = cfg.timeout;

    boot.loader.limine = {
      enable = true;
      efiSupport = true;
      maxGenerations = cfg.maxGenerations;

      # Security: disable kernel param editing at boot
      enableEditor = false;

      # Validate boot files for integrity
      validateChecksums = true;

      # OneDarkPro Theme (minimal)
      style = {
        # Background color (OneDarkPro bg)
        backdrop = colors.bg;

        # Disable branding/logo
        interface = {
          branding = null;  # No branding text or logo
        };

        # Graphical terminal colors (OneDarkPro palette)
        # Colors are semicolon-separated RRGGBB values
        graphicalTerminal = {
          # Foreground color for text
          foreground = colors.fg;

          # Standard colors: black;red;green;brown;blue;magenta;cyan;gray
          palette = lib.concatStringsSep ";" [
            colors.black   # 0: black
            colors.red     # 1: red
            colors.green   # 2: green
            colors.yellow  # 3: brown/yellow
            colors.blue    # 4: blue
            colors.purple  # 5: magenta/purple
            colors.cyan    # 6: cyan
            colors.gray    # 7: gray/white
          ];

          # Bright colors: dark gray;bright red;bright green;yellow;bright blue;bright magenta;bright cyan;white
          brightPalette = lib.concatStringsSep ";" [
            colors.brightBlack   # 8: bright black (dark gray)
            colors.red           # 9: bright red
            colors.green         # 10: bright green
            colors.yellow        # 11: bright yellow
            colors.blue          # 12: bright blue
            colors.purple        # 13: bright magenta
            colors.cyan          # 14: bright cyan
            colors.brightWhite   # 15: bright white
          ];

          # Bright foreground for highlighted text
          brightForeground = colors.brightWhite;

          # Terminal background with slight transparency
          # Format: AARRGGBB (AA = alpha, 00 = transparent, FF = opaque)
          background = "e6${colors.bg}";  # ~90% opaque

          # Bright background for selection highlighting
          brightBackground = colors.selection;

          # Margin around the terminal (pixels)
          margin = 64;
          marginGradient = 48;  # Gradient effect strength
        };
      };
    };
  };
}
