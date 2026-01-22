#!/usr/bin/env zsh
#
# VS Code Plugin
# Enhanced VS Code / VSCodium / Cursor integration with better detection and aliases
#

# Verify if any manual user choice of VS Code exists first
if [[ -n "$VSCODE" ]] && ! (( $+commands[$VSCODE] )); then
  print -u2 "[vscode] '$VSCODE' flavour not detected."
  unset VSCODE
fi

# Auto-detect VS Code flavour (prefer stable over insiders over alternatives)
if [[ -z "$VSCODE" ]]; then
  if (( $+commands[code] )); then
    VSCODE=code
  elif (( $+commands[cursor] )); then
    VSCODE=cursor
  elif (( $+commands[code-insiders] )); then
    VSCODE=code-insiders
  elif (( $+commands[codium] )); then
    VSCODE=codium
  else
    print -u2 "[vscode] No VS Code variant found. Skipping plugin."
    return 1
  fi
fi

# Export for use in other scripts
export VSCODE

# ═════════════════════════════════════════════════════════════════════════════
# TERMINAL INTEGRATION
# ═════════════════════════════════════════════════════════════════════════════

# Shell integration for terminal emulators
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  . "$($VSCODE --locate-shell-integration-path zsh 2>/dev/null)" 2>/dev/null || true
fi

# ═════════════════════════════════════════════════════════════════════════════
# MAIN FUNCTIONS
# ═════════════════════════════════════════════════════════════════════════════

# Open VS Code (directory/file or current directory)
# Filters Electron warnings about Wayland flags (they work fine, just noisy)
function vsc {
  if (( $# )); then
    $VSCODE "$@" 2>&1 | grep -v "^Warning: '.*' is not in the list of known options"
  else
    $VSCODE . 2>&1 | grep -v "^Warning: '.*' is not in the list of known options"
  fi
}

# Open workspace file
function vscw {
  if [[ -z "$1" ]]; then
    print -u2 "Usage: vscw <workspace-file>"
    return 1
  fi
  $VSCODE "$1"
}

# Open VS Code and wait for files to be closed
function vscwait {
  $VSCODE --wait "$@"
}

# Open diff between two files
function vscdiff {
  if [[ $# -lt 2 ]]; then
    print -u2 "Usage: vscdiff <file1> <file2>"
    return 1
  fi
  $VSCODE --diff "$1" "$2"
}

# ═════════════════════════════════════════════════════════════════════════════
# ALIASES - OPENING FILES
# ═════════════════════════════════════════════════════════════════════════════

alias vscode="$VSCODE"                    # Full command
alias c="$VSCODE ."                       # Quick: open current dir
alias vsc.="$VSCODE ."                    # Open current directory
alias vsca="$VSCODE --add"                # Add folder to workspace
alias vscg="$VSCODE --goto"               # Go to file:line:column
alias vscn="$VSCODE --new-window"         # New window
alias vscr="$VSCODE --reuse-window"       # Reuse existing window

# ═════════════════════════════════════════════════════════════════════════════
# ALIASES - EXTENSIONS
# ═════════════════════════════════════════════════════════════════════════════

alias vsced="$VSCODE --extensions-dir"    # Set extensions directory
alias vscie="$VSCODE --install-extension" # Install extension
alias vscue="$VSCODE --uninstall-extension" # Uninstall extension
alias vscle="$VSCODE --list-extensions"   # List extensions
alias vscde="$VSCODE --disable-extensions" # Disable all extensions

# ═════════════════════════════════════════════════════════════════════════════
# ALIASES - ADVANCED OPTIONS
# ═════════════════════════════════════════════════════════════════════════════

alias vscu="$VSCODE --user-data-dir"      # Set user data directory
alias vscp="$VSCODE --profile"            # Open with specific profile
alias vscv="$VSCODE --verbose"            # Verbose logging
alias vscl="$VSCODE --log"                # Set log level
alias vscstatus="$VSCODE --status"        # Show diagnostics

# ═════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═════════════════════════════════════════════════════════════════════════════

# List all installed extensions
function vsc-extensions {
  $VSCODE --list-extensions --show-versions
}

# Install extension from marketplace
function vsc-install {
  if [[ -z "$1" ]]; then
    print -u2 "Usage: vsc-install <extension-id>"
    print -u2 "Example: vsc-install ms-python.python"
    return 1
  fi
  $VSCODE --install-extension "$1"
}

# Uninstall extension
function vsc-uninstall {
  if [[ -z "$1" ]]; then
    print -u2 "Usage: vsc-uninstall <extension-id>"
    return 1
  fi
  $VSCODE --uninstall-extension "$1"
}
