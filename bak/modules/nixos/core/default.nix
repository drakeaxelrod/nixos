# Core NixOS modules - always imported
{ ... }:

{
  imports = [
    ./nix.nix
    ./boot.nix
    ./security.nix
    ./zsh.nix
    ./locale.nix
  ];

  # Core system packages available everywhere
  environment.localBinInPath = true;
}
