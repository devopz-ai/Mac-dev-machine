#!/bin/bash
#
# Module 01: System Essentials
# Installs Homebrew and Xcode Command Line Tools
#

set +e  # Continue on errors

# Source utilities if not already sourced
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/os_check.sh"

log_info "Installing system essentials..."

# Install Xcode Command Line Tools
install_xcode_cli() {
    log_step "Checking Xcode Command Line Tools..."

    if xcode-select -p &> /dev/null; then
        log_success "Xcode CLI Tools already installed"
        return 0
    fi

    log_step "Installing Xcode Command Line Tools..."
    log_warning "A dialog may appear. Please click 'Install' to continue."

    xcode-select --install 2>/dev/null || true

    # Wait for installation
    until xcode-select -p &> /dev/null; do
        log_info "Waiting for Xcode CLI Tools installation..."
        sleep 10
    done

    log_success "Xcode CLI Tools installed"
}

# Install Homebrew
install_homebrew() {
    log_step "Checking Homebrew..."

    if command_exists brew; then
        log_success "Homebrew already installed"

        # Update Homebrew
        log_step "Updating Homebrew..."
        brew update
        log_success "Homebrew updated"
        return 0
    fi

    log_step "Installing Homebrew..."

    # For full automation, use NONINTERACTIVE mode
    if [[ -n "$SUDO_PASSWORD" ]]; then
        # Refresh sudo before Homebrew installation
        echo "$SUDO_PASSWORD" | sudo -S -v 2>/dev/null

        # Create askpass script for Homebrew to use
        if [[ -z "$HOMEBREW_SUDO_ASKPASS" ]]; then
            local askpass_script=$(mktemp)
            chmod 700 "$askpass_script"
            cat > "$askpass_script" << ASKPASS_EOF
#!/bin/bash
echo "$SUDO_PASSWORD"
ASKPASS_EOF
            export SUDO_ASKPASS="$askpass_script"
            export HOMEBREW_SUDO_ASKPASS="$askpass_script"
        fi

        # Run Homebrew installer in non-interactive mode
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Add Homebrew to PATH for current session
    if [[ -d "/opt/homebrew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed"

    # Disable analytics
    brew analytics off
    log_info "Homebrew analytics disabled"
}

# Configure Homebrew shell integration
configure_homebrew_shell() {
    log_step "Configuring Homebrew shell integration..."

    local brew_prefix=$(get_brew_prefix)
    local shell_config="$HOME/.zshrc"

    # Add Homebrew to PATH in shell config
    local brew_init=""
    if [[ "$brew_prefix" == "/opt/homebrew" ]]; then
        brew_init='eval "$(/opt/homebrew/bin/brew shellenv)"'
    else
        brew_init='eval "$(/usr/local/bin/brew shellenv)"'
    fi

    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# Homebrew"
    append_if_missing "$shell_config" "$brew_init"

    log_success "Homebrew shell integration configured"
}

# Install Rosetta 2 for Apple Silicon
install_rosetta() {
    if [[ "$(uname -m)" != "arm64" ]]; then
        return 0
    fi

    log_step "Checking Rosetta 2..."

    if /usr/bin/pgrep -q oahd; then
        log_success "Rosetta 2 already installed"
        return 0
    fi

    log_step "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license

    log_success "Rosetta 2 installed"
}

# Install essential brew taps
install_brew_taps() {
    log_step "Adding essential Homebrew taps..."

    local taps=(
        "homebrew/cask-fonts"
        "homebrew/cask-versions"
    )

    for tap in "${taps[@]}"; do
        if ! brew tap | grep -q "^${tap}$"; then
            brew tap "$tap" 2>/dev/null || log_warning "Could not tap $tap (may not be needed)"
        fi
    done

    log_success "Homebrew taps configured"
}

# Main
main() {
    install_xcode_cli
    install_homebrew
    configure_homebrew_shell
    install_rosetta
    install_brew_taps

    log_success "System essentials completed"
}

main "$@"
