#!/bin/bash
#
# Mac Dev Machine - Update Script
# Updates all installed tools to their latest versions
#
# Usage:
#   ./update.sh                  # Update everything
#   ./update.sh --brew           # Update Homebrew packages only
#   ./update.sh --languages      # Update language runtimes only
#   ./update.sh --check          # Check for updates (dry run)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

# Parse arguments
ACTION="all"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --brew)
                ACTION="brew"
                shift
                ;;
            --languages)
                ACTION="languages"
                shift
                ;;
            --npm)
                ACTION="npm"
                shift
                ;;
            --pip)
                ACTION="pip"
                shift
                ;;
            --check)
                ACTION="check"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Mac Dev Machine - Update Script

Usage: ./update.sh [OPTIONS]

Options:
    --brew          Update Homebrew packages only
    --languages     Update language runtimes (Python, Node, etc.)
    --npm           Update global NPM packages only
    --pip           Update pip packages only
    --check         Check for available updates (dry run)
    --help, -h      Show this help message

Examples:
    ./update.sh              # Update everything
    ./update.sh --brew       # Update Homebrew packages
    ./update.sh --check      # See what would be updated

EOF
}

# Update Homebrew
update_homebrew() {
    log_section "Updating Homebrew"

    log_step "Updating Homebrew itself..."
    brew update

    log_step "Upgrading formulae..."
    brew upgrade

    log_step "Upgrading casks..."
    brew upgrade --cask

    log_step "Cleaning up..."
    brew cleanup

    log_success "Homebrew update complete"
}

# Update language runtimes
update_languages() {
    log_section "Updating Language Runtimes"

    # Python via pyenv
    if command_exists pyenv; then
        log_step "Updating pyenv..."
        brew upgrade pyenv 2>/dev/null || true

        log_info "Current Python versions:"
        pyenv versions

        log_info "To install a new Python version: pyenv install <version>"
    fi

    # Node via nvm
    if [[ -d "$HOME/.nvm" ]]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        log_step "Checking for Node.js updates..."
        log_info "Current Node version: $(node --version 2>/dev/null || echo 'not installed')"

        log_info "To update Node.js: nvm install --lts"
    fi

    # Rust via rustup
    if command_exists rustup; then
        log_step "Updating Rust..."
        rustup update
        log_success "Rust updated"
    fi

    # Go
    if command_exists go; then
        log_step "Go update..."
        brew upgrade go 2>/dev/null || log_info "Go is up to date"
    fi

    # Ruby via rbenv
    if command_exists rbenv; then
        log_step "Updating rbenv..."
        brew upgrade rbenv ruby-build 2>/dev/null || true
        log_info "To update Ruby: rbenv install <version>"
    fi

    log_success "Language updates complete"
}

# Update NPM packages
update_npm() {
    log_section "Updating NPM Packages"

    if ! command_exists npm; then
        log_warning "NPM not found"
        return 1
    fi

    log_step "Updating npm itself..."
    npm install -g npm@latest

    log_step "Checking outdated global packages..."
    npm outdated -g || true

    log_step "Updating global packages..."
    npm update -g

    log_success "NPM update complete"
}

# Update pip packages
update_pip() {
    log_section "Updating Pip Packages"

    if ! command_exists pip3; then
        log_warning "pip3 not found"
        return 1
    fi

    log_step "Upgrading pip..."
    pip3 install --upgrade pip

    log_step "Checking outdated packages..."
    pip3 list --outdated | head -20

    log_info "To update all pip packages, run:"
    echo "  pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U"

    log_success "Pip check complete"
}

# Check for updates (dry run)
check_updates() {
    log_section "Checking for Updates"

    # Homebrew
    log_step "Checking Homebrew..."
    brew update >/dev/null 2>&1

    echo ""
    echo "=== Outdated Formulae ==="
    brew outdated --formula || echo "All formulae are up to date"

    echo ""
    echo "=== Outdated Casks ==="
    brew outdated --cask || echo "All casks are up to date"

    # NPM
    if command_exists npm; then
        echo ""
        echo "=== Outdated NPM Packages ==="
        npm outdated -g 2>/dev/null || echo "All npm packages are up to date"
    fi

    # Pip
    if command_exists pip3; then
        echo ""
        echo "=== Outdated Pip Packages ==="
        pip3 list --outdated 2>/dev/null | head -10 || echo "All pip packages are up to date"
    fi

    echo ""
    log_info "Run './update.sh' to apply all updates"
}

# Update all
update_all() {
    update_homebrew
    update_languages
    update_npm
    update_pip

    log_section "Update Complete"
    log_success "All tools have been updated"
}

# Main
main() {
    parse_args "$@"

    case $ACTION in
        brew)
            update_homebrew
            ;;
        languages)
            update_languages
            ;;
        npm)
            update_npm
            ;;
        pip)
            update_pip
            ;;
        check)
            check_updates
            ;;
        all)
            update_all
            ;;
    esac
}

main "$@"
