# Rust development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    rustup
    cargo-watch
    cargo-edit
  ];

  home.sessionVariables = {
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
  };

  home.sessionPath = [
    "${config.xdg.dataHome}/cargo/bin"
  ];
}
