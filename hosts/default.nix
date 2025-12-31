# Host configurations
#
# Each host is built using lib.mkHost with its specific settings.
# Host modules are in hosts/<name>/ subdirectories.
#
{ lib }:

let
  users = import ../users;
in

{
  toaster = lib.mkHost {
    hostname = "toaster";
    users = with users; [ draxel ];
  };

  # Add more hosts:
  # laptop = lib.mkHost {
  #   hostname = "laptop";
  #   users = with users; [ draxel ];
  # };
}
