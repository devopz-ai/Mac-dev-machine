#!/bin/bash
#
# macOS version and architecture detection
#

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script only runs on macOS"
        exit 1
    fi

    local os_version=$(sw_vers -productVersion)
    local os_name=$(sw_vers -productName)
    local build=$(sw_vers -buildVersion)

    log_info "Detected: $os_name $os_version (Build $build)"

    # Extract major version
    local major_version=$(echo "$os_version" | cut -d. -f1)

    # Check minimum version (macOS 12 Monterey)
    if [[ "$major_version" -lt 12 ]]; then
        log_error "macOS 12 (Monterey) or later is required"
        log_error "Current version: $os_version"
        exit 1
    fi

    # Determine codename
    local codename=""
    case "$major_version" in
        12) codename="Monterey" ;;
        13) codename="Ventura" ;;
        14) codename="Sonoma" ;;
        15) codename="Sequoia" ;;
        *) codename="Unknown" ;;
    esac

    log_success "macOS $codename ($os_version) - Supported"

    # Export for use in other scripts
    export MACOS_VERSION="$os_version"
    export MACOS_MAJOR="$major_version"
    export MACOS_CODENAME="$codename"
}

# Check architecture (Intel vs Apple Silicon)
check_architecture() {
    local arch=$(uname -m)

    case "$arch" in
        x86_64)
            log_info "Architecture: Intel (x86_64)"
            export ARCH="intel"
            export BREW_PREFIX="/usr/local"
            ;;
        arm64)
            log_info "Architecture: Apple Silicon (arm64)"
            export ARCH="arm64"
            export BREW_PREFIX="/opt/homebrew"

            # Check Rosetta 2
            if ! /usr/bin/pgrep -q oahd; then
                log_warning "Rosetta 2 is not installed"
                log_info "Some Intel-only apps may require Rosetta 2"

                if ask_yes_no "Install Rosetta 2 now?"; then
                    log_step "Installing Rosetta 2..."
                    softwareupdate --install-rosetta --agree-to-license
                    log_success "Rosetta 2 installed"
                fi
            else
                log_success "Rosetta 2 is installed"
            fi
            ;;
        *)
            log_error "Unknown architecture: $arch"
            exit 1
            ;;
    esac
}

# Check available disk space
check_disk_space() {
    local required_gb=20
    local available_gb=$(df -g / | awk 'NR==2 {print $4}')

    log_info "Available disk space: ${available_gb}GB"

    if [[ "$available_gb" -lt "$required_gb" ]]; then
        log_warning "Low disk space. At least ${required_gb}GB recommended."
        if ! ask_yes_no "Continue anyway?"; then
            exit 1
        fi
    else
        log_success "Sufficient disk space available"
    fi
}

# Check internet connectivity
check_internet() {
    log_step "Checking internet connectivity..."

    if ping -c 1 -W 5 google.com &> /dev/null; then
        log_success "Internet connection available"
        return 0
    elif ping -c 1 -W 5 github.com &> /dev/null; then
        log_success "Internet connection available"
        return 0
    else
        log_error "No internet connection detected"
        log_error "Please check your network and try again"
        exit 1
    fi
}

# Check if running as root (we don't want that)
check_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        log_error "Do not run this script as root or with sudo"
        log_error "Run as a normal user: ./install.sh"
        exit 1
    fi
}

# Check if user has admin rights
check_admin_rights() {
    if groups | grep -q admin; then
        log_success "User has admin rights"
        return 0
    else
        log_warning "User may not have admin rights"
        log_warning "Some installations may fail"
        return 1
    fi
}

# Get macOS version info as JSON-like string
get_system_info() {
    cat << EOF
{
  "os_name": "$(sw_vers -productName)",
  "os_version": "$MACOS_VERSION",
  "os_codename": "$MACOS_CODENAME",
  "architecture": "$ARCH",
  "hostname": "$(hostname)",
  "username": "$(whoami)",
  "shell": "$SHELL"
}
EOF
}
