#!/bin/bash
#
# Mac Dev Machine - Uninstall Script
# Removes only tools that were installed by this setup
#

set +e  # Continue on errors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

STATE_DIR="$HOME/.mac-dev-machine"
STATE_FILE="$STATE_DIR/installed.txt"

print_header() {
    echo ""
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${BLUE}        Mac Dev Machine - Uninstall Script            ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo ""
}

print_warning() {
    echo -e "${YELLOW}This will remove packages installed by Mac Dev Machine.${NC}"
    echo -e "${YELLOW}Your data and configurations will be preserved.${NC}"
    echo ""
}

# Check if state file exists, auto-scan if not
check_state_file() {
    if [[ ! -f "$STATE_FILE" ]] || [[ ! -s "$STATE_FILE" ]]; then
        log_warning "No installation record found. Scanning for installed packages..."
        echo ""

        # Run the scan script
        if [[ -f "${SCRIPT_DIR}/scan-installed.sh" ]]; then
            "${SCRIPT_DIR}/scan-installed.sh"
        else
            log_error "scan-installed.sh not found"
            exit 1
        fi

        # Check if scan created the file
        if [[ ! -f "$STATE_FILE" ]] || [[ ! -s "$STATE_FILE" ]]; then
            log_error "No packages found to uninstall."
            exit 1
        fi
        echo ""
    fi
}

# Show what's installed
show_installed() {
    check_state_file

    echo -e "${CYAN}Packages installed by Mac Dev Machine:${NC}"
    echo ""

    local formulas=$(grep "^formula|" "$STATE_FILE" 2>/dev/null | wc -l | tr -d ' ')
    local casks=$(grep "^cask|" "$STATE_FILE" 2>/dev/null | wc -l | tr -d ' ')
    local npms=$(grep "^npm|" "$STATE_FILE" 2>/dev/null | wc -l | tr -d ' ')
    local pips=$(grep "^pip|" "$STATE_FILE" 2>/dev/null | wc -l | tr -d ' ')

    echo "  Homebrew Formulas: $formulas"
    echo "  Homebrew Casks:    $casks"
    echo "  NPM Packages:      $npms"
    echo "  Pip Packages:      $pips"
    echo ""
    echo "  Total: $((formulas + casks + npms + pips)) packages"
    echo ""
}

# Show detailed list
show_detailed_list() {
    check_state_file

    echo -e "${CYAN}=== Homebrew Formulas ===${NC}"
    grep "^formula|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        echo "  - $name ($pkg)"
    done
    echo ""

    echo -e "${CYAN}=== Homebrew Casks ===${NC}"
    grep "^cask|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        echo "  - $name ($pkg)"
    done
    echo ""

    echo -e "${CYAN}=== NPM Packages ===${NC}"
    grep "^npm|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        echo "  - $name ($pkg)"
    done
    echo ""

    echo -e "${CYAN}=== Pip Packages ===${NC}"
    grep "^pip|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        echo "  - $name ($pkg)"
    done
    echo ""
}

# Uninstall all formulas
uninstall_formulas() {
    log_step "Uninstalling Homebrew formulas..."

    grep "^formula|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        if brew list "$pkg" &>/dev/null; then
            log_step "Removing $name..."
            if brew uninstall "$pkg" 2>/dev/null; then
                log_success "Removed $name"
                remove_from_state "formula" "$pkg"
            else
                log_warning "Could not remove $name"
            fi
        else
            log_info "$name already removed"
            remove_from_state "formula" "$pkg"
        fi
    done
}

# Uninstall all casks
uninstall_casks() {
    log_step "Uninstalling Homebrew casks..."

    grep "^cask|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        if brew list --cask "$pkg" &>/dev/null; then
            log_step "Removing $name..."
            if brew uninstall --cask "$pkg" 2>/dev/null; then
                log_success "Removed $name"
                remove_from_state "cask" "$pkg"
            else
                log_warning "Could not remove $name"
            fi
        else
            log_info "$name already removed"
            remove_from_state "cask" "$pkg"
        fi
    done
}

# Uninstall all npm packages
uninstall_npm() {
    log_step "Uninstalling NPM packages..."

    if ! command -v npm &>/dev/null; then
        log_warning "npm not found, skipping npm packages"
        return
    fi

    grep "^npm|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        log_step "Removing $name..."
        if npm uninstall -g "$pkg" 2>/dev/null; then
            log_success "Removed $name"
            remove_from_state "npm" "$pkg"
        else
            log_warning "Could not remove $name"
        fi
    done
}

# Uninstall all pip packages
uninstall_pip() {
    log_step "Uninstalling Pip packages..."

    local pip_cmd="pip3"
    if ! command -v pip3 &>/dev/null; then
        if command -v pip &>/dev/null; then
            pip_cmd="pip"
        else
            log_warning "pip not found, skipping pip packages"
            return
        fi
    fi

    grep "^pip|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        log_step "Removing $name..."
        if $pip_cmd uninstall -y "$pkg" 2>/dev/null; then
            log_success "Removed $name"
            remove_from_state "pip" "$pkg"
        else
            log_warning "Could not remove $name"
        fi
    done
}

# Uninstall version managers and their installations
uninstall_version_managers() {
    log_step "Uninstalling version managers..."

    # Python via pyenv
    if command -v pyenv &>/dev/null; then
        log_step "Removing Python versions..."
        for version in $(pyenv versions --bare 2>/dev/null); do
            pyenv uninstall -f "$version" 2>/dev/null || true
        done
        rm -rf "$HOME/.pyenv"
        log_success "Removed pyenv and Python versions"
    fi

    # Node via nvm
    if [[ -d "$HOME/.nvm" ]]; then
        rm -rf "$HOME/.nvm"
        log_success "Removed nvm and Node versions"
    fi

    # Ruby via rbenv
    if command -v rbenv &>/dev/null; then
        for version in $(rbenv versions --bare 2>/dev/null); do
            rbenv uninstall -f "$version" 2>/dev/null || true
        done
        rm -rf "$HOME/.rbenv"
        log_success "Removed rbenv and Ruby versions"
    fi

    # Rust
    if [[ -d "$HOME/.cargo" ]]; then
        rm -rf "$HOME/.cargo"
        rm -rf "$HOME/.rustup"
        log_success "Removed Rust and Cargo"
    fi

    # Go
    if [[ -d "$HOME/go" ]]; then
        rm -rf "$HOME/go"
        log_success "Removed Go workspace"
    fi
}

# Clean shell configuration
cleanup_shell_config() {
    log_step "Cleaning shell configuration..."

    local shell_config="$HOME/.zshrc"
    local backup="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"

    if [[ -f "$shell_config" ]]; then
        cp "$shell_config" "$backup"
        log_info "Backed up .zshrc to $backup"

        # Create temp file
        local temp_file=$(mktemp)

        # Filter out our added configurations
        awk '
        /^# Pyenv$/,/pyenv virtualenv-init/ { next }
        /^# NVM$/,/bash_completion/ { next }
        /^# Java$/,/JAVA_HOME\/bin/ { next }
        /^# Go$/,/GOPATH\/bin/ { next }
        /^# Rust$/,/cargo\/env/ { next }
        /^# Ruby$/,/rbenv init/ { next }
        /^# PostgreSQL$/,/postgresql@16/ { next }
        /^# AI Tools$/,/ANTHROPIC_API_KEY/ { next }
        { print }
        ' "$shell_config" > "$temp_file"

        mv "$temp_file" "$shell_config"
        log_success "Shell configuration cleaned"
    fi
}

# Uninstall everything
uninstall_all() {
    check_state_file
    show_installed

    echo -e "${RED}WARNING: This will uninstall ALL packages installed by Mac Dev Machine!${NC}"
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " confirm

    if [[ "$confirm" != "yes" ]]; then
        log_info "Uninstall cancelled."
        exit 0
    fi

    echo ""
    uninstall_pip
    uninstall_npm
    uninstall_casks
    uninstall_formulas
    uninstall_version_managers
    cleanup_shell_config

    # Cleanup Homebrew
    log_step "Cleaning up Homebrew..."
    brew cleanup --prune=all 2>/dev/null || true
    brew autoremove 2>/dev/null || true

    # Remove state file
    rm -f "$STATE_FILE"

    log_success "Uninstall completed!"
    echo ""
    echo -e "${YELLOW}Note: Homebrew itself was NOT removed.${NC}"
    echo -e "${YELLOW}To remove Homebrew, run:${NC}"
    echo -e "${BLUE}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\"${NC}"
}

# Uninstall by type
uninstall_by_type() {
    local type="$1"

    check_state_file

    case "$type" in
        formula|formulas)
            uninstall_formulas
            ;;
        cask|casks)
            uninstall_casks
            ;;
        npm)
            uninstall_npm
            ;;
        pip)
            uninstall_pip
            ;;
        *)
            log_error "Unknown type: $type"
            log_info "Valid types: formula, cask, npm, pip"
            exit 1
            ;;
    esac
}

# Interactive menu
show_menu() {
    echo "What would you like to uninstall?"
    echo ""
    echo "  1) Show installed packages"
    echo "  2) Show detailed list"
    echo "  3) Uninstall Homebrew Formulas only"
    echo "  4) Uninstall Homebrew Casks only"
    echo "  5) Uninstall NPM packages only"
    echo "  6) Uninstall Pip packages only"
    echo "  7) Uninstall version managers (pyenv, nvm, rbenv, rust)"
    echo "  8) Clean shell configuration only"
    echo ""
    echo "  A) UNINSTALL EVERYTHING"
    echo "  Q) Quit"
    echo ""
}

# Force rescan
force_scan() {
    log_step "Rescanning installed packages..."
    rm -f "$STATE_FILE"
    "${SCRIPT_DIR}/scan-installed.sh"
}

# Usage help
usage() {
    echo ""
    echo -e "${BLUE}Mac Dev Machine - Uninstall Script${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
    echo "Remove packages installed by Mac Dev Machine setup."
    echo "Tracks installations in ~/.mac-dev-machine/installed.txt"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  ./uninstall.sh [OPTIONS]"
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo "  --list, -l          Show installed packages summary"
    echo "  --detailed, -d      Show detailed package list"
    echo "  --scan, -s          Force rescan of installed packages"
    echo "  --interactive, -i   Interactive menu mode"
    echo "  --all, -a           Uninstall everything (requires confirmation)"
    echo "  --type, -t TYPE     Uninstall by type: formula, cask, npm, pip"
    echo "  --help, -h          Show this help"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  ./uninstall.sh --list           # Show what's tracked"
    echo "  ./uninstall.sh --detailed       # Show full package list"
    echo "  ./uninstall.sh --interactive    # Interactive menu"
    echo "  ./uninstall.sh --type cask      # Remove all casks"
    echo "  ./uninstall.sh --all            # Remove everything"
    echo ""
    echo -e "${CYAN}State File:${NC}"
    echo "  ~/.mac-dev-machine/installed.txt"
    echo ""
}

# Main
main() {
    print_header

    # Show help if no arguments
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    # Parse arguments
    case "${1:-}" in
        --list|-l)
            check_state_file
            show_installed
            exit 0
            ;;
        --detailed|-d)
            check_state_file
            show_detailed_list
            exit 0
            ;;
        --scan|-s)
            force_scan
            exit 0
            ;;
        --all|-a)
            uninstall_all
            exit 0
            ;;
        --type|-t)
            check_state_file
            uninstall_by_type "${2:-}"
            exit 0
            ;;
        --interactive|-i)
            # Continue to interactive mode below
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac

    # Interactive mode
    print_warning

    # Auto-scan if no state file
    check_state_file

    while true; do
        show_menu
        read -p "Enter choice [1-8, A, Q]: " choice
        echo ""

        case $choice in
            1) show_installed ;;
            2) show_detailed_list ;;
            3) uninstall_formulas ;;
            4) uninstall_casks ;;
            5) uninstall_npm ;;
            6) uninstall_pip ;;
            7) uninstall_version_managers ;;
            8) cleanup_shell_config ;;
            [Aa]) uninstall_all; exit 0 ;;
            [Qq]) log_info "Exiting."; exit 0 ;;
            *) log_warning "Invalid choice." ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
        clear
        print_header
    done
}

main "$@"
