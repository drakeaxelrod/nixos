# draxel - Self-contained user module
#
# Combines NixOS user configuration with Home Manager.
# Import this module in mkHost to add the user to a host.
#
{ config, lib, pkgs, inputs, ... }:

let
  profileImage = "${inputs.self}/assets/profile/me.jpg";
in
{
  # NixOS user configuration
  users.users.draxel = {
    isNormalUser = true;
    description = "draxel";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "input" "video" "audio" "docker" "uucp"];
    initialPassword = "changeme";
  };

  # Profile image for display managers (SDDM, GDM, etc.)
  # AccountsService icon - system-wide user avatar
  system.activationScripts.draxelAvatar = lib.stringAfter [ "users" ] ''
    mkdir -p /var/lib/AccountsService/icons
    cp ${profileImage} /var/lib/AccountsService/icons/draxel
    chmod 644 /var/lib/AccountsService/icons/draxel

    # AccountsService config to use the icon
    mkdir -p /var/lib/AccountsService/users
    cat > /var/lib/AccountsService/users/draxel << 'EOF'
    [User]
    Icon=/var/lib/AccountsService/icons/draxel
    EOF
  '';

  # Home Manager configuration
  home-manager.users.draxel = import ./home;
}
