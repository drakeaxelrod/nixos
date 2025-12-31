# GRC - Generic Colouriser for colorizing command output
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    grc
  ];

  # ZSH integration - automatically colorize supported commands
  programs.zsh.initContent = lib.mkAfter ''
    # GRC colorization
    if command -v grc &> /dev/null; then
      # Common commands that benefit from colorization
      alias diff='grc diff'
      alias gcc='grc gcc'
      alias g++='grc g++'
      alias as='grc as'
      alias gas='grc gas'
      alias ld='grc ld'
      alias netstat='grc netstat'
      alias ping='grc ping'
      alias traceroute='grc traceroute'
      alias make='grc make'
      alias mount='grc mount'
      alias ps='grc ps'
      alias dig='grc dig'
      alias ifconfig='grc ifconfig'
      alias df='grc df'
      alias du='grc du'
      alias ip='grc ip'
      alias env='grc env'
      alias lsof='grc lsof'
      alias free='grc free'
      alias findmnt='grc findmnt'
      alias fdisk='grc fdisk'
      alias blkid='grc blkid'
      alias id='grc id'
      alias iptables='grc iptables'
      alias ss='grc ss'
      alias uptime='grc uptime'
    fi
  '';
}
