# delta - Better git diff with syntax highlighting
{ config, pkgs, lib, ... }:

{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;  # Required: integrate with git

    options = {
      # Appearance
      side-by-side = true;
      line-numbers = true;
      navigate = true;

      # Syntax theme
      syntax-theme = "OneHalfDark";

      # File decorations
      file-style = "bold yellow";
      file-decoration-style = "yellow box";

      # Line number styles
      line-numbers-left-format = "{nm:>4}│";
      line-numbers-right-format = "{np:>4}│";

      # Diff styles
      minus-style = "syntax #3f0001";
      minus-emph-style = "syntax #901011";
      plus-style = "syntax #002800";
      plus-emph-style = "syntax #006000";

      # Hunk header
      hunk-header-decoration-style = "blue box";
      hunk-header-style = "file line-number syntax";
    };
  };
}
