# Python development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # System Python with libraries available globally (no venv needed for these).
    # For project-scoped deps, use uv/virtualenv as before.
    (python312.withPackages (ps: with ps; [
      pip
      virtualenv
      reportlab  # PDF generation library
    ]))
    uv  # Fast Python package installer
  ];

  home.sessionVariables = {
    PYTHONUSERBASE = "${config.xdg.dataHome}/python";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
  };

  home.sessionPath = [
    "${config.xdg.dataHome}/python/bin"
  ];
}
