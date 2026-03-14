#!/bin/bash
#
# Module 11: Optional Apps
# Installs productivity, utility, and optional applications
#

set +e  # Continue on errors

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing optional apps..."

# Install window management
install_window_management() {
    log_step "Installing window management tools..."
    install_cask "rectangle" "Rectangle"
    install_cask "raycast" "Raycast"
    install_cask "alfred" "Alfred" || true
    log_success "Window management completed"
}

# Install productivity tools
install_productivity() {
    log_step "Installing productivity tools..."
    install_cask "notion" "Notion"
    install_cask "obsidian" "Obsidian"
    log_success "Productivity tools completed"
}

# Install file management
install_file_management() {
    log_step "Installing file management tools..."
    install_cask "the-unarchiver" "The Unarchiver"
    install_cask "appcleaner" "AppCleaner"
    log_success "File management completed"
}

# Install API testing tools
install_api_tools() {
    log_step "Installing API testing tools..."
    install_cask "postman" "Postman"
    install_cask "insomnia" "Insomnia"
    install_cask "bruno" "Bruno" || true
    log_success "API testing tools completed"
}

# Install media tools
install_media_tools() {
    log_step "Installing media tools..."
    install_formula "ffmpeg" "FFmpeg"
    install_formula "imagemagick" "ImageMagick"
    install_cask "vlc" "VLC"
    log_success "Media tools completed"
}

# Install security tools
install_security_tools() {
    log_step "Installing security tools..."
    install_cask "bitwarden" "Bitwarden"
    install_cask "keepassxc" "KeePassXC" || true
    log_success "Security tools completed"
}

# Install system utilities
install_system_utilities() {
    log_step "Installing system utilities..."
    install_cask "stats" "Stats"
    install_cask "hiddenbar" "Hidden Bar" || true
    install_cask "monitorcontrol" "MonitorControl" || true
    log_success "System utilities completed"
}

# Main
main() {
    install_window_management
    install_productivity
    install_file_management
    install_api_tools
    install_media_tools
    install_security_tools
    install_system_utilities
    log_success "Optional apps completed"
}

main "$@"
