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

# Don't exit on errors - we want to continue checking all tools
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Track missing tools for install suggestions
MISSING_FORMULAS=()
MISSING_CASKS=()
MISSING_PIP=()

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

# Check if cask app is installed (required)
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

# Check if cask app is installed (optional - no fail)
check_optional_app() {
    local app_name="$1"
    local cask_name="${2:-}"
    local app_path="/Applications/${app_name}.app"
    local user_app_path="$HOME/Applications/${app_name}.app"

    if [[ -d "$app_path" ]] || [[ -d "$user_app_path" ]]; then
        echo -e "${GREEN}[PASS]${NC} $app_name.app (optional)"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}[WARN]${NC} $app_name.app - not installed (optional)"
        ((WARNINGS++))
        [[ -n "$cask_name" ]] && MISSING_CASKS+=("$cask_name")
        return 0
    fi
}

# Warning check (non-critical) - always returns 0 to not break script
check_optional() {
    local cmd="$1"
    local name="${2:-$cmd}"
    local formula="${3:-$cmd}"

    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}[PASS]${NC} $name (optional)"
        ((PASSED++))
    else
        echo -e "${YELLOW}[WARN]${NC} $name - not installed (optional)"
        ((WARNINGS++))
        MISSING_FORMULAS+=("$formula")
    fi
    return 0
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
    check_optional "pyenv" "pyenv" "pyenv"

    # Node.js
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    check_command "node" "Node.js" "--version"
    check_command "npm" "npm" "--version"

    if [[ "$QUICK_MODE" != true ]]; then
        # Java
        check_optional "java" "Java" "temurin"

        # Go
        check_optional "go" "Go" "go"

        # Rust
        check_optional "rustc" "Rust" "rust"
        check_optional "cargo" "Cargo" "rust"

        # Ruby
        check_optional "ruby" "Ruby" "ruby"
    fi
}

# Validate Git tools
validate_git() {
    section "Git Tools"

    check_command "git" "Git" "--version"
    check_command "gh" "GitHub CLI" "--version"

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional "glab" "GitLab CLI" "glab"
        check_optional "lazygit" "lazygit" "lazygit"
    fi
}

# Validate DevOps tools
validate_devops() {
    section "DevOps Tools"

    check_optional "docker" "Docker" "docker"

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional "kubectl" "kubectl" "kubectl"
        check_optional "helm" "Helm" "helm"
        check_optional "terraform" "Terraform" "terraform"
        check_optional "packer" "Packer" "packer"
        check_optional "vagrant" "Vagrant" "vagrant"
        check_optional "ansible" "Ansible" "ansible"
        check_optional "aws" "AWS CLI" "awscli"
        check_optional "gcloud" "Google Cloud CLI" "google-cloud-sdk"
        check_optional "az" "Azure CLI" "azure-cli"
        check_optional "pulumi" "Pulumi" "pulumi"
        check_optional "k9s" "k9s" "k9s"
        check_optional "minikube" "Minikube" "minikube"
        check_optional "kind" "Kind" "kind"
    fi
}

# Validate virtualization tools
validate_virtualization() {
    if [[ "$QUICK_MODE" == true ]]; then
        return
    fi

    section "Virtualization"

    # All virtualization tools are optional
    check_optional_app "VirtualBox" "virtualbox"
    check_optional_app "Multipass" "multipass"
    check_optional_app "UTM" "utm"
    check_optional "qemu-system-aarch64" "QEMU" "qemu"
    check_optional "lima" "Lima" "lima"
    check_optional "colima" "Colima" "colima"
    check_optional "podman" "Podman" "podman"
}

# Validate editors & terminals
validate_editors() {
    section "Editors & Terminals"

    check_optional_app "Visual Studio Code" "visual-studio-code"
    check_optional_app "iTerm" "iterm2"

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional_app "Cursor" "cursor"
        check_optional "nvim" "Neovim" "neovim"
        check_optional_app "PyCharm CE" "pycharm-ce"
        check_optional_app "IntelliJ IDEA CE" "intellij-idea-ce"
        check_optional_app "Zed" "zed"
        check_optional_app "Sublime Text" "sublime-text"
        check_optional_app "Warp" "warp"
        check_optional_app "Alacritty" "alacritty"
        check_optional "tmux" "tmux" "tmux"
        check_optional "starship" "Starship" "starship"
    fi
}

# Validate browsers
validate_browsers() {
    section "Browsers"

    check_optional_app "Google Chrome" "google-chrome"
    check_optional_app "Firefox" "firefox"

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional_app "Brave Browser" "brave-browser"
        check_optional_app "Arc" "arc"
        check_optional_app "Firefox Developer Edition" "firefox-developer-edition"
    fi
}

# Validate CLI tools
validate_cli() {
    section "CLI Tools"

    check_command "jq" "jq"

    if [[ "$QUICK_MODE" != true ]]; then
        check_optional "bat" "bat" "bat"
        check_optional "eza" "eza" "eza"
        check_optional "rg" "ripgrep" "ripgrep"
        check_optional "fd" "fd" "fd"
        check_optional "fzf" "fzf" "fzf"
        check_optional "zoxide" "zoxide" "zoxide"
        check_optional "yq" "yq" "yq"
        check_optional "htop" "htop" "htop"
        check_optional "btop" "btop" "btop"
        check_optional "tldr" "tldr" "tldr"
        check_optional "httpie" "httpie" "httpie" || check_optional "http" "httpie" "httpie"
        check_optional "wget" "wget" "wget"
        check_optional "tree" "tree" "tree"
        check_optional "ncdu" "ncdu" "ncdu"
    fi
}

# Validate AI tools
validate_ai() {
    if [[ "$QUICK_MODE" == true ]]; then
        return
    fi

    section "AI/ML Tools"

    # Local LLM runners
    check_optional "ollama" "Ollama" "ollama"
    check_optional_app "LM Studio" "lm-studio"
    check_optional_app "GPT4All" "gpt4all"
    check_optional_app "Jan" "jan"

    # AI development tools
    check_optional "llama.cpp" "llama.cpp" "llama.cpp" || check_optional "llama-cli" "llama.cpp" "llama.cpp"
    check_optional "huggingface-cli" "Hugging Face CLI" "huggingface-cli"

    # Python AI packages (check pip)
    if command -v pip3 &> /dev/null; then
        if pip3 show aider-chat &>/dev/null; then
            echo -e "${GREEN}[PASS]${NC} Aider (pip)"
            ((PASSED++))
        else
            echo -e "${YELLOW}[WARN]${NC} Aider - not installed (optional)"
            ((WARNINGS++))
            MISSING_PIP+=("aider-chat")
        fi

        if pip3 show langchain &>/dev/null; then
            echo -e "${GREEN}[PASS]${NC} LangChain (pip)"
            ((PASSED++))
        else
            echo -e "${YELLOW}[WARN]${NC} LangChain - not installed (optional)"
            ((WARNINGS++))
            MISSING_PIP+=("langchain")
        fi

        if pip3 show litellm &>/dev/null; then
            echo -e "${GREEN}[PASS]${NC} LiteLLM (pip)"
            ((PASSED++))
        else
            echo -e "${YELLOW}[WARN]${NC} LiteLLM - not installed (optional)"
            ((WARNINGS++))
            MISSING_PIP+=("litellm")
        fi
    fi

    # AI Image generation
    check_optional_app "DiffusionBee" "diffusionbee"
    check_optional_app "Draw Things" "drawthings"
}

# Validate network/security tools
validate_network() {
    if [[ "$QUICK_MODE" == true ]]; then
        return
    fi

    section "Network & Security Tools"

    check_optional_app "Wireshark" "wireshark"
    check_optional "nmap" "nmap" "nmap"
    check_optional "mtr" "mtr" "mtr"
    check_optional "mitmproxy" "mitmproxy" "mitmproxy"
    check_optional "mkcert" "mkcert" "mkcert"
    check_optional "ngrok" "ngrok" "ngrok"
}

# Validate communication apps
validate_communication() {
    if [[ "$QUICK_MODE" == true ]]; then
        return
    fi

    section "Communication"

    check_optional_app "Slack" "slack"
    check_optional_app "Discord" "discord"
    check_optional_app "zoom.us" "zoom"
    check_optional_app "Microsoft Teams" "microsoft-teams"
    check_optional_app "WhatsApp" "whatsapp"
    check_optional_app "Telegram" "telegram"
}

# Validate databases
validate_databases() {
    if [[ "$QUICK_MODE" == true ]]; then
        return
    fi

    section "Databases"

    check_optional "psql" "PostgreSQL" "postgresql@16"
    check_optional "redis-cli" "Redis" "redis"
    check_optional "mysql" "MySQL" "mysql"
    check_optional "sqlite3" "SQLite" "sqlite"
    check_optional_app "DBeaver" "dbeaver-community"
    check_optional_app "TablePlus" "tableplus"
    check_optional_app "MongoDB Compass" "mongodb-compass"
    check_optional "pgcli" "pgcli" "pgcli"
    check_optional "mycli" "mycli" "mycli"
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

    # Show install commands for missing optional tools
    if [[ $WARNINGS -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}To install missing optional tools:${NC}"
        echo ""

        if [[ ${#MISSING_FORMULAS[@]} -gt 0 ]]; then
            # Remove duplicates
            local unique_formulas=($(printf '%s\n' "${MISSING_FORMULAS[@]}" | sort -u))
            echo -e "  ${CYAN}# CLI tools (Homebrew formulas)${NC}"
            echo -e "  brew install ${unique_formulas[*]}"
            echo ""
        fi

        if [[ ${#MISSING_CASKS[@]} -gt 0 ]]; then
            # Remove duplicates
            local unique_casks=($(printf '%s\n' "${MISSING_CASKS[@]}" | sort -u))
            echo -e "  ${CYAN}# GUI apps (Homebrew casks)${NC}"
            echo -e "  brew install --cask ${unique_casks[*]}"
            echo ""
        fi

        if [[ ${#MISSING_PIP[@]} -gt 0 ]]; then
            # Remove duplicates
            local unique_pip=($(printf '%s\n' "${MISSING_PIP[@]}" | sort -u))
            echo -e "  ${CYAN}# Python packages${NC}"
            echo -e "  pip3 install ${unique_pip[*]}"
            echo ""
        fi

        echo -e "  ${CYAN}# Or run the full installer${NC}"
        echo -e "  ./install.sh --package advanced"
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
    validate_virtualization
    validate_editors
    validate_browsers
    validate_cli
    validate_ai
    validate_network
    validate_databases
    validate_communication

    print_summary

    # Exit with error if any essential tools failed
    if [[ $FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
