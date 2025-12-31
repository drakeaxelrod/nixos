# System-wide user settings
#
# Individual users are defined in users/<name>/ as self-contained modules.
# They are composed per-host in flake.nix via: users = with users; [ draxel ];
#
{ config, lib, pkgs, ... }:

{
  config = {
    # Enable zsh system-wide (user shells can use it)
    programs.zsh.enable = true;

    # Passwordless sudo for wheel group
    security.sudo.wheelNeedsPassword = lib.mkDefault false;
  };
}
