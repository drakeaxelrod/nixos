# Toaster VM definitions
{ ... }:

{
  virtualisation.vms = {
    win11 = import ./win11.nix;
  };
}
