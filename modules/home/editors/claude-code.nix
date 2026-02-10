# Claude Code configuration
{ config, pkgs, lib, ... }:

{
  programs.claude-code = {
    enable = true;
    settings = {
      includeCoAuthoredBy = false;
      permissions = {
        additionalDirectories = [ ];
        allow = [ "WebFetch" ];
        disableBypassPermissionsMode = "disable";
      };
      statusLine = {
        command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')]  $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
        padding = 0;
        type = "command";
      };
      theme = "dark";

      # Plugin marketplaces
      marketplaces = [
        {
          name = "claude-plugins-official";
          type = "github";
          url = "anthropics/claude-plugins-official";
        }
        {
          name = "superpowers-marketplace";
          type = "github";
          url = "obra/superpowers-marketplace";
        }
      ];

      # Enabled plugins (format: "plugin-name@marketplace-name")
      enabledPlugins = {
        "context7@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
      };
    };
  };
}
