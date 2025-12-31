#!/usr/bin/env bash
# NixOS flake operations script
# Intelligent, extensible NixOS management tool

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_NAME="nx"
readonly FLAKE_DIR="${FLAKE_DIR:-$HOME/.config/nixos}"
readonly DEFAULT_HOST="${NX_DEFAULT_HOST:-toaster}"
readonly DEFAULT_JOBS="${NX_JOBS:-8}"
readonly DEFAULT_CORES="${NX_CORES:-2}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# ============================================================================
# Utility Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}${NC} $*"
}

log_success() {
    echo -e "${GREEN}${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}${NC} $*"
}

log_error() {
    echo -e "${RED}${NC} $*" >&2
}

log_cmd() {
    echo -e "${MAGENTA}${NC} $*"
}

# Check if we're in the flake directory
ensure_flake_dir() {
    if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
        log_error "Flake directory not found: $FLAKE_DIR"
        log_info "Set FLAKE_DIR environment variable to your NixOS configuration path"
        exit 1
    fi
    cd "$FLAKE_DIR"
}

# Get current hostname
get_current_host() {
    hostname
}

# Detect available hosts from flake
get_available_hosts() {
    if [[ -f "$FLAKE_DIR/flake.nix" ]]; then
        nix flake show --json 2>/dev/null | \
            jq -r '.nixosConfigurations | keys[]' 2>/dev/null || echo "$DEFAULT_HOST"
    else
        echo "$DEFAULT_HOST"
    fi
}

# Validate host exists
validate_host() {
    local host=$1
    local available_hosts
    available_hosts=$(get_available_hosts)

    if ! echo "$available_hosts" | grep -q "^${host}$"; then
        log_error "Host '$host' not found in flake"
        log_info "Available hosts:"
        echo "$available_hosts" | sed 's/^/  - /'
        exit 1
    fi
}

# ============================================================================
# NixOS Operations
# ============================================================================

cmd_switch() {
    local host=${1:-$DEFAULT_HOST}
    shift || true

    ensure_flake_dir
    validate_host "$host"

    log_info "Switching to configuration: $host"
    log_cmd "sudo nixos-rebuild switch --flake \".#$host\" -j $DEFAULT_JOBS --cores $DEFAULT_CORES $*"

    sudo nixos-rebuild switch --flake ".#$host" -j "$DEFAULT_JOBS" --cores "$DEFAULT_CORES" "$@"
    log_success "System switched to $host configuration"
}

cmd_boot() {
    local host=${1:-$DEFAULT_HOST}
    shift || true

    ensure_flake_dir
    validate_host "$host"

    log_info "Building boot configuration: $host"
    log_cmd "sudo nixos-rebuild boot --flake \".#$host\" -j $DEFAULT_JOBS --cores $DEFAULT_CORES $*"

    sudo nixos-rebuild boot --flake ".#$host" -j "$DEFAULT_JOBS" --cores "$DEFAULT_CORES" "$@"
    log_success "Boot configuration updated for $host (effective after reboot)"
}

cmd_test() {
    local host=${1:-$DEFAULT_HOST}
    shift || true

    ensure_flake_dir
    validate_host "$host"

    log_info "Testing configuration: $host"
    log_cmd "sudo nixos-rebuild test --flake \".#$host\" -j $DEFAULT_JOBS --cores $DEFAULT_CORES $*"

    sudo nixos-rebuild test --flake ".#$host" -j "$DEFAULT_JOBS" --cores "$DEFAULT_CORES" "$@"
    log_success "Configuration tested (not added to boot menu)"
}

cmd_dry() {
    local host=${1:-$DEFAULT_HOST}
    shift || true

    ensure_flake_dir
    validate_host "$host"

    log_info "Dry run for: $host"
    log_cmd "nixos-rebuild dry-build --flake \".#$host\" $*"

    nixos-rebuild dry-build --flake ".#$host" "$@"
}

cmd_build() {
    local host=${1:-$DEFAULT_HOST}
    shift || true

    ensure_flake_dir
    validate_host "$host"

    log_info "Building configuration: $host"
    log_cmd "nixos-rebuild build --flake \".#$host\" $*"

    nixos-rebuild build --flake ".#$host" "$@"
    log_success "Configuration built (./result)"
}

cmd_update() {
    ensure_flake_dir

    log_info "Updating flake inputs"
    log_cmd "nix flake update $*"

    nix flake update "$@"
    log_success "Flake inputs updated"

    # Show what changed
    if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
        log_info "Changes to flake.lock:"
        git diff flake.lock | grep -E "^\+|^-" | grep -v "^+++" | grep -v "^---" || log_info "No changes"
    fi
}

cmd_diff() {
    local host=${1:-$DEFAULT_HOST}
    shift || true

    ensure_flake_dir
    validate_host "$host"

    if ! command -v nvd &> /dev/null; then
        log_error "nvd not found. Install it with: nix profile install nixpkgs#nvd"
        exit 1
    fi

    log_info "Building and comparing: $host"
    log_cmd "nixos-rebuild build --flake \".#$host\" && nvd diff /run/current-system result"

    nixos-rebuild build --flake ".#$host" "$@"
    nvd diff /run/current-system result
}

cmd_gc() {
    log_info "Running garbage collection"

    # System-wide GC
    log_cmd "sudo nix-collect-garbage -d"
    sudo nix-collect-garbage -d

    # User GC
    log_cmd "nix-collect-garbage -d"
    nix-collect-garbage -d

    log_success "Garbage collection complete"

    # Show disk usage
    log_info "Nix store size:"
    du -sh /nix/store 2>/dev/null || log_warn "Could not determine store size"
}

cmd_fmt() {
    ensure_flake_dir

    log_info "Formatting Nix files"

    if command -v nixpkgs-fmt &> /dev/null; then
        log_cmd "find . -name '*.nix' -exec nixpkgs-fmt {} +"
        find . -name '*.nix' -exec nixpkgs-fmt {} +
        log_success "Files formatted with nixpkgs-fmt"
    elif command -v alejandra &> /dev/null; then
        log_cmd "alejandra ."
        alejandra .
        log_success "Files formatted with alejandra"
    else
        log_error "No formatter found. Install nixpkgs-fmt or alejandra"
        exit 1
    fi
}

cmd_check() {
    ensure_flake_dir

    log_info "Checking flake"
    log_cmd "nix flake check $*"

    nix flake check "$@"
    log_success "Flake check passed"
}

cmd_show() {
    ensure_flake_dir

    log_info "Flake outputs"
    log_cmd "nix flake show"

    nix flake show
}

cmd_info() {
    ensure_flake_dir

    log_info "Flake metadata"
    log_cmd "nix flake metadata"

    nix flake metadata
}

cmd_list_generations() {
    log_info "System generations"
    log_cmd "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system"

    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
}

cmd_rollback() {
    local generation=${1:-}

    if [[ -z "$generation" ]]; then
        log_error "Usage: nx rollback <generation>"
        log_info "Run 'nx generations' to see available generations"
        exit 1
    fi

    log_warn "Rolling back to generation $generation"
    log_cmd "sudo nix-env --switch-generation $generation --profile /nix/var/nix/profiles/system"

    sudo nix-env --switch-generation "$generation" --profile /nix/var/nix/profiles/system

    log_cmd "sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch"
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

    log_success "Rolled back to generation $generation"
}

cmd_search() {
    local query=${1:-}

    if [[ -z "$query" ]]; then
        log_error "Usage: nx search <package>"
        exit 1
    fi

    log_info "Searching for: $query"
    log_cmd "nix search nixpkgs $query"

    nix search nixpkgs "$query"
}

cmd_repl() {
    ensure_flake_dir

    log_info "Starting Nix REPL with flake"
    log_cmd "nix repl --file flake.nix"

    nix repl --file flake.nix
}

# ============================================================================
# Help System
# ============================================================================

print_help() {
    cat << EOF
${CYAN}$SCRIPT_NAME${NC} - NixOS flake operations

${YELLOW}Usage:${NC}
  $SCRIPT_NAME <action> [host] [options...]

${YELLOW}Actions:${NC}
  ${GREEN}Rebuild Operations:${NC}
    switch             Switch to new configuration
    boot               Build for next boot only
    test               Test without adding to boot menu
    build              Build without activating
    dry                Dry run - show what would be built

  ${GREEN}Maintenance:${NC}
    update             Update flake inputs
    diff               Show diff between current and new config
    gc                 Garbage collect old generations
    fmt                Format all Nix files

  ${GREEN}Information:${NC}
    check              Check flake for errors
    show               Show flake outputs
    info               Show flake metadata
    generations        List system generations
    search <pkg>       Search for packages

  ${GREEN}Advanced:${NC}
    rollback <gen>     Rollback to specific generation
    repl               Start Nix REPL with flake

${YELLOW}Options:${NC}
  Host defaults to '$DEFAULT_HOST' if not specified
  Additional options are passed to nixos-rebuild

${YELLOW}Environment Variables:${NC}
  FLAKE_DIR          Path to flake directory (default: ~/.config/nixos)
  NX_DEFAULT_HOST    Default host name (default: toaster)
  NX_JOBS            Parallel build jobs (default: 8)
  NX_CORES           Cores per job (default: 2)

${YELLOW}Examples:${NC}
  $SCRIPT_NAME switch              # Switch current host to new config
  $SCRIPT_NAME switch toaster      # Switch specific host
  $SCRIPT_NAME update              # Update flake inputs
  $SCRIPT_NAME diff                # Show what would change
  $SCRIPT_NAME switch --show-trace # Switch with trace output
  $SCRIPT_NAME rollback 42         # Rollback to generation 42
EOF
}

# ============================================================================
# Main Dispatcher
# ============================================================================

main() {
    local action=${1:-help}
    shift || true

    case "$action" in
        switch|sw)
            cmd_switch "$@"
            ;;
        boot|b)
            cmd_boot "$@"
            ;;
        test|t)
            cmd_test "$@"
            ;;
        dry|dr)
            cmd_dry "$@"
            ;;
        build|bd)
            cmd_build "$@"
            ;;
        update|up)
            cmd_update "$@"
            ;;
        diff|df)
            cmd_diff "$@"
            ;;
        gc)
            cmd_gc "$@"
            ;;
        fmt|format)
            cmd_fmt "$@"
            ;;
        check|chk)
            cmd_check "$@"
            ;;
        show|sh)
            cmd_show "$@"
            ;;
        info|i)
            cmd_info "$@"
            ;;
        generations|gen|list)
            cmd_list_generations "$@"
            ;;
        rollback|rb)
            cmd_rollback "$@"
            ;;
        search|s)
            cmd_search "$@"
            ;;
        repl|r)
            cmd_repl "$@"
            ;;
        help|--help|-h)
            print_help
            exit 0
            ;;
        *)
            log_error "Unknown action: $action"
            echo ""
            print_help
            exit 1
            ;;
    esac
}

main "$@"
