# Development tools and languages
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Rust
    rustup
    cargo-watch
    cargo-edit

    # Go
    go
    gopls
    delve

    # Node.js
    nodejs_22
    pnpm
    yarn

    # Python
    python312
    python312Packages.pip
    python312Packages.virtualenv
    uv  # Fast Python package installer

    # Java
    jdk21

    # C/C++
    gcc
    gnumake
    cmake
    ninja

    # Lua
    lua
    luajit

    # Nix
    nixpkgs-fmt
    nil  # Nix LSP

    # Database clients
    postgresql
    sqlite

    # API testing
    curl
    jq
    yq

    # Build tools
    just  # Command runner
    direnv
  ];

  # Go environment
  home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/.local/share/go";
    GOMODCACHE = "${config.home.homeDirectory}/.cache/go/pkg/mod";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/go/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];
}
