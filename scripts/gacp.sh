#!/usr/bin/env bash
# Git Add, Commit, Push with AI-generated commit messages
# Tries: GitHub Copilot CLI -> Ollama -> fallback

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_NAME="gacp"
readonly OLLAMA_MODELS=("llama3.2" "llama3.1" "mistral" "llama2" "codellama")
readonly FALLBACK_MESSAGE="update"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ============================================================================
# Utility Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

# ============================================================================
# AI Commit Message Generation
# ============================================================================

generate_with_copilot() {
    local diff_stat="$1"
    local diff_content="$2"

    # Check if gh copilot is available and authenticated
    if ! command -v gh &>/dev/null; then
        return 1
    fi

    # Check if copilot extension is installed
    if ! gh extension list 2>/dev/null | grep -q "copilot"; then
        return 1
    fi

    log_info "Generating with GitHub Copilot..."

    local prompt="Generate a concise git commit message for these changes following conventional commits format:
- Use imperative mood (Add, Fix, Update, Remove, Refactor)
- Format: type(scope): description
- Types: feat, fix, docs, style, refactor, test, chore
- Max 50 chars, no period at end
- Be specific about what changed

Stats:
$diff_stat

Diff (truncated):
$diff_content

Reply with ONLY the commit message, nothing else."

    local result
    result=$(echo "$prompt" | gh copilot suggest -t shell 2>/dev/null | head -1 | sed 's/^[`]*//' | sed 's/[`]*$//' | tr -d '\n')

    # Validate result
    if [[ -n "$result" && ${#result} -ge 5 && ${#result} -le 100 ]]; then
        echo "$result"
        return 0
    fi

    return 1
}

generate_with_ollama() {
    local diff_stat="$1"
    local diff_content="$2"

    if ! command -v ollama &>/dev/null; then
        return 1
    fi

    # Check if ollama service is running
    if ! ollama list &>/dev/null; then
        return 1
    fi

    local prompt="Generate a git commit message for these changes. Rules:
- Use imperative mood (Add, Fix, Update, Remove, Refactor)
- Format: type(scope): description
- Types: feat, fix, docs, style, refactor, test, chore
- Max 50 chars for first line
- No period at end
- Be specific

Stats:
$diff_stat

Diff:
$diff_content

Reply with ONLY the commit message, no quotes or explanation."

    for model in "${OLLAMA_MODELS[@]}"; do
        if ollama list 2>/dev/null | grep -q "$model"; then
            log_info "Generating with Ollama ($model)..."
            local result
            result=$(echo "$prompt" | ollama run "$model" 2>/dev/null | head -3 | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')

            # Validate result
            if [[ -n "$result" && ${#result} -ge 5 && ${#result} -le 100 && ! "$result" =~ ^(Here|I\'ll|This|The|Sure) ]]; then
                echo "$result"
                return 0
            fi
        fi
    done

    return 1
}

generate_commit_message() {
    local diff_stat diff_content

    # Get diff information
    diff_stat=$(git diff --cached --stat)
    diff_content=$(git diff --cached | head -500)

    # Try Copilot first (uses existing VS Code auth)
    if generate_with_copilot "$diff_stat" "$diff_content"; then
        return 0
    fi

    # Fall back to Ollama
    if generate_with_ollama "$diff_stat" "$diff_content"; then
        return 0
    fi

    return 1
}

# ============================================================================
# Main Logic
# ============================================================================

print_help() {
    cat << EOF
${CYAN}$SCRIPT_NAME${NC} - Git Add, Commit (AI), Push

${YELLOW}Usage:${NC}
  $SCRIPT_NAME [-m "message"] [-y] [-n]

${YELLOW}Options:${NC}
  -m "msg"    Use manual commit message (skip AI)
  -y          Auto-confirm (no prompt)
  -n          Dry run (don't actually commit/push)
  -h, --help  Show this help

${YELLOW}AI Backends (tried in order):${NC}
  1. GitHub Copilot CLI (gh copilot) - uses VS Code auth
  2. Ollama (local) - ollama pull llama3.2
  3. Fallback: "update"

${YELLOW}Setup:${NC}
  Copilot: gh extension install github/gh-copilot
  Ollama:  nix-shell -p ollama && ollama pull llama3.2

${YELLOW}Examples:${NC}
  $SCRIPT_NAME                    # AI generates message, prompts to confirm
  $SCRIPT_NAME -m "fix: typo"     # Use manual message
  $SCRIPT_NAME -y                 # Auto-confirm AI message
EOF
}

main() {
    local manual_message=""
    local auto_confirm=false
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m)
                manual_message="$2"
                shift 2
                ;;
            -y|--yes)
                auto_confirm=true
                shift
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done

    # Check if we're in a git repo
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        log_error "Not in a git repository"
        exit 1
    fi

    # Stage all changes
    log_info "Staging changes..."
    git add -A

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log_warn "No changes to commit"
        exit 0
    fi

    # Show what's staged
    echo ""
    log_info "Staged changes:"
    git diff --cached --stat
    echo ""

    # Get commit message
    local commit_msg
    if [[ -n "$manual_message" ]]; then
        commit_msg="$manual_message"
    else
        commit_msg=$(generate_commit_message) || {
            log_warn "AI generation failed, using fallback"
            commit_msg="$FALLBACK_MESSAGE"
        }
    fi

    # Show message
    echo -e "${CYAN}Commit message:${NC} $commit_msg"
    echo ""

    # Confirm
    if [[ "$dry_run" == true ]]; then
        log_info "[Dry run] Would commit and push with message: $commit_msg"
        exit 0
    fi

    if [[ "$auto_confirm" != true ]]; then
        read -r -p "Proceed with commit and push? [Y/n/e(dit)] " confirm
        confirm=${confirm:-Y}

        case "$confirm" in
            [Yy]*)
                ;;
            [Ee]*)
                read -r -p "Enter new message: " commit_msg
                ;;
            *)
                log_warn "Aborted. Changes remain staged."
                exit 0
                ;;
        esac
    fi

    # Commit
    log_info "Committing..."
    git commit -m "$commit_msg"

    # Push
    log_info "Pushing..."
    if git push 2>&1; then
        log_success "Done!"
    else
        log_warn "Push failed. Commit was successful. Try 'git push' manually."
        exit 1
    fi
}

main "$@"
