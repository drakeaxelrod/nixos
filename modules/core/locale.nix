# Localization settings - timezone, locale, keymap
{ config, lib, ... }:

{
  options.modules.core.locale = {
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
    time.timeZone = config.modules.core.locale.timezone;
    i18n.defaultLocale = config.modules.core.locale.locale;
    console.keyMap = config.modules.core.locale.keymap;
  };
}
