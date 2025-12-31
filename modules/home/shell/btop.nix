# btop - Modern system monitor with beautiful UI
{ config, pkgs, lib, ... }:

{
  programs.btop = {
    enable = true;

    settings = {
      # Theme
      color_theme = "Default";
      theme_background = false;

      # Update rate in milliseconds
      update_ms = 1000;

      # Show processes as tree
      proc_tree = true;

      # Show detailed stats
      show_detailed = true;

      # Temperature unit (celsius/fahrenheit/kelvin)
      temp_scale = "celsius";

      # Network graphs
      net_auto = true;
      net_sync = true;

      # Show IO stats
      show_io_stat = true;

      # Show battery
      show_battery = true;

      # Vim keys
      vim_keys = true;
    };
  };
}
