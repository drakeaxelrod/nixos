# Home Manager users - returns attrset of user configs
{ config, pkgs, inputs, ... }:

{
  # Import user configurations
  draxel = import ./users/draxel;
}
