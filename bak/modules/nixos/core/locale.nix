# Localization configuration
{ config, pkgs, lib, vars, ... }:

{
  # Timezone (from vars or default)
  time.timeZone = vars.timezone or "UTC";

  # Default locale
  i18n.defaultLocale = vars.locale or "en_US.UTF-8";

  # Extra locale settings for consistent formatting
  i18n.extraLocaleSettings = {
    LC_ADDRESS = vars.locale or "en_US.UTF-8";
    LC_IDENTIFICATION = vars.locale or "en_US.UTF-8";
    LC_MEASUREMENT = vars.locale or "en_US.UTF-8";
    LC_MONETARY = vars.locale or "en_US.UTF-8";
    LC_NAME = vars.locale or "en_US.UTF-8";
    LC_NUMERIC = vars.locale or "en_US.UTF-8";
    LC_PAPER = vars.locale or "en_US.UTF-8";
    LC_TELEPHONE = vars.locale or "en_US.UTF-8";
    LC_TIME = vars.locale or "en_US.UTF-8";
  };

  # Console keymap
  console.keyMap = vars.keymap or "us";
}
