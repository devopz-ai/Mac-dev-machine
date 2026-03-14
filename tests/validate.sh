#!/bin/bash
#
# Mac Dev Machine - Validation Script
# Verifies that tools are installed correctly
#
# Usage:
#   ./tests/validate.sh              # Run all checks
#   ./tests/validate.sh --quick      # Quick check (essential tools only)
#   ./tests/validate.sh --verbose    # Detailed output
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Options
QUICK_MODE=false
VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick|-q)
                QUICK_MODE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                echo "Usage: ./validate.sh [--quick] [--verbose]"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Check if command exists and optionally show version
check_command() {
    local cmd="$1"
    local name="${2:-$cmd}"
    local version_flag="${3:---version}"

    if command -v "$cmd" &> /dev/null; then
        if [[ "$VERBOSE" == true ]]; then
            local version=$("$cmd" $version_flag 2>&1 | head -n1)
            echo -e "${GREEN}[PASS]${NC} $name: $version"
        else
            echo -e "${GREEN}[PASS]${NC} $name"
        fi
        ((PASSED++))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $name - not found"
        ((FAILED++))
        return 1
    fi
}

# Check if cask app is installed
check_app() {
    local app_name="$1"
    local app_path="/Applications/${app_name}.app"
    local user_app_path="$HOME/Applications/${app_name}.app"

    if [[ -d "$app_path" ]] || [[ -d "$user_app_path" ]]; then
        echo -e "${GREEN}[PASS]${NC} $app_name.app"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $app_name.app - not found"
        ((FAILED++))
        return 1
    fi
}

# Warning check (non-critical)
check_optional() {
    local cmd="$1"
    local name="${2:-$cmd}"

    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}[PASS]${NC} $name (optional)"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}[WARN]${NC} $name - not installed (optional)"
        ((WARNINGS++))
        return 1
    fi
}

# Print section header
section() {
    echo ""
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# Validate system essentials
validate_system() {
    section "System Essentials"

    # macOS info
    echo -e "${CYAN}macOS:${NC} $(sw_vers -productVersion) ($(uname -m))"

    # Xcode CLI Tools
    if xcode-select -p &> /dev/null; then
        echo -e "${GREEN}[PASS]${NC} Xcode CLI Tools"
        ((PASSED++))
    else
        echo -e "${RED}[FAIL]${NC} Xcode CLI Tools"
        ((FAILED++))
    fi

    # Homebrew
    check_command "brew" "Homebrew" "--version"
}

# Validate languages
validate_languages() {
    section "Programming Languages"

    # Python
    check_command "python3" "Python" "--version"
    check_optional "pyenv" "pyenv"

    # Node.js
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    check_command "node" "Node.js" "--version"
    check_command "npm" "npm" "--version"

    if [[ "$QUICK_MODE" != true ]]; then
        # Java
        check_optional "java" "Java" "--version"

        # Go
        check_optional "go" "Go" "version"

        # Rust
        check_optional "rustc" "Rust" "--version"
        check_optional "cargo" "Cargo" "--version"

        # Ruby
        check_optional "ruby" "Ruby" "--version"
    fi
}

# Validate Git tools
validate_git() {
    section "Git Tools"

    check_command "git" "Git" "--version"
    check_command "gh" "GitHub CLI" "--version"

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional "glab" "GitLab CLI"
        check_optional "lazygit" "lazygit"
    fi
}

# Validate DevOps tools
validate_devops() {
    section "DevOps Tools"

    check_optional "docker" "Docker" "--version"

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional "kubectl" "kubectl"
        check_optional "helm" "Helm"
        check_optional "terraform" "Terraform"
    fi
}

# Validate editors
validate_editors() {
    section "Editors"

    check_app "Visual Studio Code"

    if [[ "$QUICK_MODE" != true ]]; then
        check_app "Cursor"
        check_optional "nvim" "Neovim"
        check_app "iTerm"
    fi
}

# Validate browsers
validate_browsers() {
    section "Browsers"

    check_app "Google Chrome"

    if [[ "$QUICK_MODE" != true ]]; then
        check_app "Firefox"
        check_app "Brave Browser"
    fi
}

# Validate CLI tools
validate_cli() {
    section "CLI Tools"

    check_command "jq" "jq"

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional "bat" "bat"
        check_optional "eza" "eza"
        check_optional "rg" "ripgrep"
        check_optional "fd" "fd"
        check_optional "fzf" "fzf"
    fi
}

# Validate AI tools
validate_ai() {
    if [[ "$QUICK_MODE" == true ]]; then
        return
    fi

    section "AI Tools"

    check_optional "ollama" "Ollama"
    check_app "LM Studio"
}

# Validate databases
validate_databases() {
    if [[ "$QUICK_MODE" == true ]]; then
        return
    fi

    section "Databases"

    check_optional "psql" "PostgreSQL"
    check_optional "redis-cli" "Redis"
}

# Print summary
print_summary() {
    echo ""
    echo -e "${PURPLE}===================================================================${NC}"
    echo -e "${PURPLE}  Validation Summary${NC}"
    echo -e "${PURPLE}===================================================================${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}   $PASSED"
    echo -e "  ${RED}Failed:${NC}   $FAILED"
    echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""

    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}All essential tools are installed correctly!${NC}"
    else
        echo -e "${RED}Some tools are missing. Run ./install.sh to install them.${NC}"
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}Some optional tools are not installed.${NC}"
    fi

    echo ""
}

# Main
main() {
    parse_args "$@"

    echo ""
    echo -e "${PURPLE}===================================================================${NC}"
    echo -e "${PURPLE}  Mac Dev Machine - Validation${NC}"
    echo -e "${PURPLE}===================================================================${NC}"

    validate_system
    validate_languages
    validate_git
    validate_devops
    validate_editors
    validate_browsers
    validate_cli
    validate_ai
    validate_databases

    print_summary

    # Exit with error if any essential tools failed
    if [[ $FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
