#!/bin/bash
#
# Module 09: Web Browsers
# Installs browsers and browser development tools
#

set -e

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing browsers..."

# Install mainstream browsers
install_mainstream_browsers() {
    log_step "Installing mainstream browsers..."
    install_cask "google-chrome" "Google Chrome"
    install_cask "firefox" "Firefox"
    install_cask "microsoft-edge" "Microsoft Edge"
    log_success "Mainstream browsers completed"
}

# Install developer browsers
install_dev_browsers() {
    log_step "Installing developer browsers..."
    install_cask "firefox-developer-edition" "Firefox Developer Edition"
    install_cask "chromium" "Chromium" || true
    log_success "Developer browsers completed"
}

# Install privacy browsers
install_privacy_browsers() {
    log_step "Installing privacy browsers..."
    install_cask "brave-browser" "Brave Browser"
    install_cask "tor-browser" "Tor Browser" || true
    log_success "Privacy browsers completed"
}

# Install alternative browsers
install_alternative_browsers() {
    log_step "Installing alternative browsers..."
    install_cask "arc" "Arc Browser"
    install_cask "opera" "Opera"
    log_success "Alternative browsers completed"
}

# Install browser automation tools
install_browser_automation() {
    log_step "Installing browser automation tools..."
    install_formula "chromedriver" "ChromeDriver"
    install_formula "geckodriver" "GeckoDriver"
    install_pip "selenium" "Selenium"
    if command_exists npm; then
        install_npm_global "playwright" "Playwright"
        install_npm_global "puppeteer" "Puppeteer"
        install_npm_global "web-ext" "web-ext"
    fi
    log_success "Browser automation completed"
}

# Main
main() {
    install_mainstream_browsers
    install_dev_browsers
    install_privacy_browsers
    install_alternative_browsers
    install_browser_automation
    log_success "Browsers completed"
}

main "$@"
