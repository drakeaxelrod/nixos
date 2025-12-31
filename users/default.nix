# User configurations
#
# Each user is a self-contained module with NixOS user + Home Manager config.
# Users are composed per-host in hosts/default.nix via: users = with users; [ draxel ];
#
{
  draxel = ./draxel;
  bamse = ./bamse;

  # Add more users:
  # guest = ./guest;
}
