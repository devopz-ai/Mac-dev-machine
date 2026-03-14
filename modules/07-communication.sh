#!/bin/bash
#
# Module 07: Communication Apps
# Installs messaging and collaboration tools
#

set +e  # Continue on errors

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing communication apps..."

# Install team messaging
install_team_messaging() {
    log_step "Installing team messaging apps..."
    install_cask "slack" "Slack"
    install_cask "microsoft-teams" "Microsoft Teams"
    log_success "Team messaging completed"
}

# Install community chat
install_community_chat() {
    log_step "Installing community chat apps..."
    install_cask "discord" "Discord"
    log_success "Community chat completed"
}

# Install personal messaging
install_personal_messaging() {
    log_step "Installing personal messaging apps..."
    install_cask "whatsapp" "WhatsApp"
    install_cask "telegram" "Telegram"
    install_cask "signal" "Signal"
    log_success "Personal messaging completed"
}

# Install video conferencing
install_video_conferencing() {
    log_step "Installing video conferencing apps..."
    install_cask "zoom" "Zoom"
    install_cask "loom" "Loom"
    log_success "Video conferencing completed"
}

# Main
main() {
    install_team_messaging
    install_community_chat
    install_personal_messaging
    install_video_conferencing
    log_success "Communication apps completed"
}

main "$@"
