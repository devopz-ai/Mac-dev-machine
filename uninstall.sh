#!/bin/bash
#
# Mac Dev Machine - Uninstall Script
# Removes tools installed by this repository
#
# Usage:
#   ./uninstall.sh                    # Interactive mode
#   ./uninstall.sh --tool <name>      # Uninstall specific tool
#   ./uninstall.sh --all              # Uninstall everything (careful!)
#   ./uninstall.sh --list             # List installed tools
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

# Parse arguments
ACTION=""
TOOL_NAME=""
AUTO_YES=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tool|-t)
                ACTION="tool"
                TOOL_NAME="$2"
                shift 2
                ;;
            --all)
                ACTION="all"
                shift
                ;;
            --list|-l)
                ACTION="list"
                shift
                ;;
            --yes|-y)
                AUTO_YES=true
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
Mac Dev Machine - Uninstall Script

Usage: ./uninstall.sh [OPTIONS]

Options:
    --tool, -t <name>   Uninstall a specific tool
    --all               Uninstall all tools (use with caution)
    --list, -l          List all installed tools from this repo
    --yes, -y           Skip confirmation prompts
    --help, -h          Show this help message

Examples:
    ./uninstall.sh --list
    ./uninstall.sh --tool docker
    ./uninstall.sh --tool "visual-studio-code"
    ./uninstall.sh --all --yes

EOF
}

# List installed tools
list_installed() {
    log_section "Installed Tools"

    echo ""
    echo "=== Homebrew Formulae ==="
    brew list --formula 2>/dev/null | head -50 || echo "None"

    echo ""
    echo "=== Homebrew Casks ==="
    brew list --cask 2>/dev/null | head -50 || echo "None"

    echo ""
    echo "=== Global NPM Packages ==="
    npm list -g --depth=0 2>/dev/null | tail -n +2 | head -20 || echo "None"

    echo ""
    echo "=== Pip Packages ==="
    pip3 list 2>/dev/null | head -30 || echo "None"

    echo ""
    log_info "Use './uninstall.sh --tool <name>' to remove a specific tool"
}

# Uninstall a specific tool
uninstall_tool() {
    local tool="$1"

    log_step "Looking for: $tool"

    # Check if it's a cask
    if brew list --cask "$tool" &>/dev/null; then
        log_warning "Found cask: $tool"
        if [[ "$AUTO_YES" == true ]] || ask_yes_no "Uninstall $tool?"; then
            brew uninstall --cask "$tool"
            log_success "Uninstalled cask: $tool"
        fi
        return 0
    fi

    # Check if it's a formula
    if brew list "$tool" &>/dev/null; then
        log_warning "Found formula: $tool"
        if [[ "$AUTO_YES" == true ]] || ask_yes_no "Uninstall $tool?"; then
            brew uninstall "$tool"
            log_success "Uninstalled formula: $tool"
        fi
        return 0
    fi

    # Check if it's an npm package
    if npm list -g "$tool" &>/dev/null; then
        log_warning "Found npm package: $tool"
        if [[ "$AUTO_YES" == true ]] || ask_yes_no "Uninstall $tool?"; then
            npm uninstall -g "$tool"
            log_success "Uninstalled npm package: $tool"
        fi
        return 0
    fi

    # Check if it's a pip package
    if pip3 show "$tool" &>/dev/null; then
        log_warning "Found pip package: $tool"
        if [[ "$AUTO_YES" == true ]] || ask_yes_no "Uninstall $tool?"; then
            pip3 uninstall -y "$tool"
            log_success "Uninstalled pip package: $tool"
        fi
        return 0
    fi

    log_error "Tool not found: $tool"
    return 1
}

# Uninstall all tools (dangerous!)
uninstall_all() {
    log_warning "This will uninstall ALL tools installed by this repository!"
    log_warning "This action cannot be undone."
    echo ""

    if [[ "$AUTO_YES" != true ]]; then
        read -p "Type 'yes' to confirm: " confirm
        if [[ "$confirm" != "yes" ]]; then
            log_info "Cancelled."
            exit 0
        fi
    fi

    log_section "Uninstalling All Tools"

    # Uninstall casks first (GUI apps)
    log_step "Uninstalling casks..."
    local casks=$(brew list --cask 2>/dev/null)
    for cask in $casks; do
        log_info "Removing: $cask"
        brew uninstall --cask "$cask" 2>/dev/null || true
    done

    # Uninstall formulae
    log_step "Uninstalling formulae..."
    local formulae=$(brew list --formula 2>/dev/null)
    for formula in $formulae; do
        # Skip critical system tools
        if [[ "$formula" == "openssl"* ]] || [[ "$formula" == "readline" ]]; then
            continue
        fi
        log_info "Removing: $formula"
        brew uninstall "$formula" 2>/dev/null || true
    done

    # Cleanup
    log_step "Cleaning up..."
    brew cleanup 2>/dev/null || true

    log_success "Uninstallation complete"
    log_info "Note: Homebrew itself was NOT removed"
    log_info "To remove Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
}

# Interactive mode
interactive_mode() {
    log_section "Uninstall Tool"
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) List installed tools"
    echo "  2) Uninstall a specific tool"
    echo "  3) Uninstall all tools"
    echo "  4) Exit"
    echo ""

    read -p "Enter choice [1-4]: " choice

    case $choice in
        1)
            list_installed
            ;;
        2)
            echo ""
            read -p "Enter tool name to uninstall: " tool
            if [[ -n "$tool" ]]; then
                uninstall_tool "$tool"
            fi
            ;;
        3)
            uninstall_all
            ;;
        4)
            exit 0
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Main
main() {
    parse_args "$@"

    case $ACTION in
        list)
            list_installed
            ;;
        tool)
            if [[ -z "$TOOL_NAME" ]]; then
                log_error "Please specify a tool name"
                exit 1
            fi
            uninstall_tool "$TOOL_NAME"
            ;;
        all)
            uninstall_all
            ;;
        *)
            interactive_mode
            ;;
    esac
}

main "$@"
