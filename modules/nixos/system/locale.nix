# Localization settings - timezone, locale, keymap
{ config, lib, ... }:

{
  options.modules.system.locale = {
    timezone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Stockholm";
      description = "System timezone";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "System locale";
    };

    keymap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Console keymap";
    };
  };

  config = {
    time.timeZone = config.modules.system.locale.timezone;

    i18n = {
      defaultLocale = config.modules.system.locale.locale;

      # Extra locale settings for consistent formatting
      extraLocaleSettings = {
        LC_ADDRESS = config.modules.system.locale.locale;
        LC_IDENTIFICATION = config.modules.system.locale.locale;
        LC_MEASUREMENT = config.modules.system.locale.locale;
        LC_MONETARY = config.modules.system.locale.locale;
        LC_NAME = config.modules.system.locale.locale;
        LC_NUMERIC = config.modules.system.locale.locale;
        LC_PAPER = config.modules.system.locale.locale;
        LC_TELEPHONE = config.modules.system.locale.locale;
        LC_TIME = config.modules.system.locale.locale;
      };
    };

    console.keyMap = config.modules.system.locale.keymap;
  };
}
