# Neovim configuration
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set tabstop=2
      set shiftwidth=2
      set smartindent
      set clipboard=unnamedplus
      set ignorecase
      set smartcase
      set termguicolors
    '';

    # Add plugins as needed
    # plugins = with pkgs.vimPlugins; [ ... ];
  };
}
