#!/bin/bash
#
# Mac Dev Machine Setup - Main Installation Script
# https://github.com/devopz-ai/Mac-dev-machine
#
# Usage:
#   ./install.sh                         # Interactive mode
#   ./install.sh --package standard      # Specific package tier
#   ./install.sh --package advanced --yes  # Non-interactive
#   ./install.sh --show-packages         # Show what's in each package
#   ./install.sh --config                # Use user-config.yaml
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library files
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/os_check.sh"
source "${SCRIPT_DIR}/lib/tool_check.sh"
source "${SCRIPT_DIR}/lib/state.sh"

# Default values
PACKAGE_TIER=""
AUTO_YES=false
SKIP_DOTFILES=false
USE_CONFIG=false
SHOW_PACKAGES=false
LOG_FILE=""
STATE_FILE="$HOME/.mac-dev-machine-state.yaml"

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --package|-p)
                PACKAGE_TIER="$2"
                shift 2
                ;;
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --skip-dotfiles)
                SKIP_DOTFILES=true
                shift
                ;;
            --config|-c)
                USE_CONFIG=true
                shift
                ;;
            --show-packages|--list)
                SHOW_PACKAGES=true
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
Mac Dev Machine Setup

Usage: ./install.sh [OPTIONS]

Options:
    --package, -p <tier>   Package tier: light, standard, advanced
    --yes, -y              Non-interactive mode, accept all defaults
    --config, -c           Use config/user-config.yaml for customization
    --skip-dotfiles        Skip dotfiles configuration
    --show-packages        Show what's included in each package tier
    --help, -h             Show this help message

Package Tiers:
    light      Essential tools only (~15 min, ~5GB)
    standard   Recommended for most developers (~30 min, ~15GB)
    advanced   Everything for power users (~60 min, ~30GB)

Examples:
    ./install.sh                        # Interactive mode
    ./install.sh --show-packages        # See what's in each package
    ./install.sh --package light        # Minimal installation
    ./install.sh --package standard     # Recommended installation
    ./install.sh --package advanced -y  # Full install, non-interactive
    ./install.sh --config               # Use custom config file

Other Scripts:
    ./update.sh                         # Update installed tools
    ./uninstall.sh                      # Remove tools

EOF
}

# Show what's in each package
show_package_contents() {
    clear
    echo ""
    echo -e "${BLUE}==================================================================${NC}"
    echo -e "${BLUE}          Mac Dev Machine - Package Contents${NC}"
    echo -e "${BLUE}==================================================================${NC}"

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  LIGHT PACKAGE - Essential tools for basic development${NC}"
    echo -e "${GREEN}  Estimated time: ~15 minutes | Disk space: ~5GB${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}System:${NC}"
    echo "  - Homebrew (package manager)"
    echo "  - Xcode Command Line Tools"
    echo "  - Rosetta 2 (Apple Silicon only)"
    echo ""
    echo -e "${CYAN}Terminal:${NC}"
    echo "  - iTerm2"
    echo ""
    echo -e "${CYAN}Editors:${NC}"
    echo "  - Visual Studio Code"
    echo "  - Neovim"
    echo ""
    echo -e "${CYAN}Languages:${NC}"
    echo "  - Python (via pyenv)"
    echo "  - Node.js (via nvm)"
    echo ""
    echo -e "${CYAN}Git:${NC}"
    echo "  - Git"
    echo "  - GitHub CLI (gh)"
    echo ""
    echo -e "${CYAN}CLI Tools:${NC}"
    echo "  - jq (JSON processor)"
    echo "  - bat (better cat)"
    echo "  - ripgrep (fast grep)"
    echo "  - fzf (fuzzy finder)"
    echo "  - htop (process viewer)"
    echo ""
    echo -e "${CYAN}Browsers:${NC}"
    echo "  - Google Chrome"
    echo "  - Firefox"
    echo ""

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  STANDARD PACKAGE - Recommended for most developers${NC}"
    echo -e "${YELLOW}  Estimated time: ~30 minutes | Disk space: ~15GB${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${PURPLE}Includes everything in LIGHT, plus:${NC}"
    echo ""
    echo -e "${CYAN}Terminal:${NC}"
    echo "  - tmux (terminal multiplexer)"
    echo "  - Starship (shell prompt)"
    echo "  - Oh My Zsh"
    echo ""
    echo -e "${CYAN}Editors:${NC}"
    echo "  - Cursor (AI code editor)"
    echo "  - PyCharm CE"
    echo ""
    echo -e "${CYAN}Languages:${NC}"
    echo "  - TypeScript"
    echo "  - Go"
    echo "  - Java (Temurin JDK)"
    echo "  - Rust (via rustup)"
    echo ""
    echo -e "${CYAN}Git:${NC}"
    echo "  - Git LFS"
    echo "  - GitLab CLI (glab)"
    echo "  - lazygit (TUI for git)"
    echo "  - git-delta (better diff)"
    echo ""
    echo -e "${CYAN}DevOps:${NC}"
    echo "  - Docker Desktop"
    echo "  - kubectl"
    echo "  - Helm"
    echo "  - Terraform"
    echo ""
    echo -e "${CYAN}CLI Tools:${NC}"
    echo "  - yq (YAML processor)"
    echo "  - eza (better ls)"
    echo "  - fd (better find)"
    echo "  - zoxide (smart cd)"
    echo "  - wget"
    echo "  - httpie"
    echo "  - tree"
    echo ""
    echo -e "${CYAN}Browsers:${NC}"
    echo "  - Brave Browser"
    echo ""
    echo -e "${CYAN}Databases:${NC}"
    echo "  - PostgreSQL 16"
    echo "  - Redis"
    echo "  - DBeaver Community"
    echo ""
    echo -e "${CYAN}Communication:${NC}"
    echo "  - Slack"
    echo "  - Discord"
    echo "  - Zoom"
    echo ""
    echo -e "${CYAN}Apps:${NC}"
    echo "  - Rectangle (window manager)"
    echo "  - Postman (API testing)"
    echo "  - The Unarchiver"
    echo ""

    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ADVANCED PACKAGE - Complete setup for power users${NC}"
    echo -e "${RED}  Estimated time: ~60 minutes | Disk space: ~30GB+${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${PURPLE}Includes everything in STANDARD, plus:${NC}"
    echo ""
    echo -e "${CYAN}Terminal:${NC}"
    echo "  - Warp, Alacritty, Kitty"
    echo "  - zsh-autosuggestions"
    echo "  - zsh-syntax-highlighting"
    echo ""
    echo -e "${CYAN}Editors:${NC}"
    echo "  - IntelliJ IDEA CE"
    echo "  - JetBrains Toolbox"
    echo "  - GoLand, WebStorm, DataGrip"
    echo "  - Zed"
    echo "  - Sublime Text"
    echo ""
    echo -e "${CYAN}Languages:${NC}"
    echo "  - Ruby (via rbenv)"
    echo "  - Bun"
    echo "  - Deno"
    echo ""
    echo -e "${CYAN}DevOps:${NC}"
    echo "  - k9s (K8s TUI)"
    echo "  - Minikube, Kind"
    echo "  - kubectx"
    echo "  - Terraform, Terragrunt, tflint"
    echo "  - Ansible"
    echo "  - AWS CLI"
    echo "  - Azure CLI"
    echo "  - Google Cloud SDK"
    echo "  - Pulumi"
    echo "  - Lens (K8s IDE)"
    echo ""
    echo -e "${CYAN}Network:${NC}"
    echo "  - Wireshark"
    echo "  - nmap"
    echo "  - ngrok"
    echo "  - mitmproxy"
    echo "  - mkcert"
    echo "  - telnet, mtr"
    echo ""
    echo -e "${CYAN}AI & LLM Tools:${NC}"
    echo "  - Ollama (local LLM)"
    echo "  - LM Studio"
    echo "  - GPT4All"
    echo "  - Jan"
    echo "  - Aider (AI pair programming)"
    echo "  - Open Interpreter"
    echo "  - Shell GPT"
    echo "  - LiteLLM"
    echo "  - LangChain"
    echo "  - OpenAI, Anthropic SDKs"
    echo ""
    echo -e "${CYAN}CLI Tools:${NC}"
    echo "  - btop (better htop)"
    echo "  - ncdu (disk usage)"
    echo "  - tldr (simplified man pages)"
    echo "  - thefuck (command correction)"
    echo "  - shellcheck"
    echo ""
    echo -e "${CYAN}Browsers:${NC}"
    echo "  - Firefox Developer Edition"
    echo "  - Arc"
    echo "  - Chromium"
    echo "  - Tor Browser"
    echo "  - Opera"
    echo ""
    echo -e "${CYAN}Databases:${NC}"
    echo "  - MySQL"
    echo "  - MongoDB"
    echo "  - SQLite"
    echo "  - TablePlus"
    echo "  - MongoDB Compass"
    echo "  - pgAdmin 4"
    echo "  - mycli, pgcli, litecli"
    echo ""
    echo -e "${CYAN}Communication:${NC}"
    echo "  - Microsoft Teams"
    echo "  - WhatsApp"
    echo "  - Telegram"
    echo "  - Signal"
    echo ""
    echo -e "${CYAN}Apps:${NC}"
    echo "  - Raycast (launcher)"
    echo "  - Alfred"
    echo "  - Notion"
    echo "  - Obsidian"
    echo "  - Insomnia (API testing)"
    echo "  - Bruno (API testing)"
    echo "  - VLC"
    echo "  - FFmpeg, ImageMagick"
    echo "  - Bitwarden, KeePassXC"
    echo "  - Stats (system monitor)"
    echo "  - Hidden Bar"
    echo "  - AppCleaner"
    echo ""

    echo -e "${BLUE}==================================================================${NC}"
    echo ""
    echo "To install a package:"
    echo -e "  ${GREEN}./install.sh --package light${NC}"
    echo -e "  ${YELLOW}./install.sh --package standard${NC}"
    echo -e "  ${RED}./install.sh --package advanced${NC}"
    echo ""
    echo "To customize (exclude tools you don't want):"
    echo "  1. cp config/user-config.yaml.example config/user-config.yaml"
    echo "  2. Edit config/user-config.yaml"
    echo "  3. ./install.sh --config"
    echo ""
}

# Package selection menu
select_package() {
    if [[ -n "$PACKAGE_TIER" ]]; then
        return
    fi

    echo ""
    log_section "Select Package Tier"
    echo ""
    echo "  1) light      Essential tools (~15 min, ~5GB)"
    echo "                VS Code, Python, Node.js, Git, Chrome"
    echo ""
    echo "  2) standard   Recommended for most developers (~30 min, ~15GB)"
    echo "                + Cursor, Go, Java, Docker, Terraform, PostgreSQL"
    echo ""
    echo "  3) advanced   Complete setup for power users (~60 min, ~30GB+)"
    echo "                + AI tools, Wireshark, all cloud CLIs, everything"
    echo ""
    echo "  4) show       Show detailed package contents"
    echo ""

    if [[ "$AUTO_YES" == true ]]; then
        PACKAGE_TIER="standard"
        log_info "Auto-selecting package: standard"
        return
    fi

    read -p "Enter choice [1-4]: " choice
    case $choice in
        1) PACKAGE_TIER="light" ;;
        2) PACKAGE_TIER="standard" ;;
        3) PACKAGE_TIER="advanced" ;;
        4)
            show_package_contents
            select_package
            return
            ;;
        *)
            log_error "Invalid choice. Using 'standard' package."
            PACKAGE_TIER="standard"
            ;;
    esac

    log_success "Selected package: $PACKAGE_TIER"
}

# Load user config if exists
load_user_config() {
    local config_file="${SCRIPT_DIR}/config/user-config.yaml"

    if [[ "$USE_CONFIG" == true ]] && [[ -f "$config_file" ]]; then
        log_info "Loading user configuration..."

        # Read package from config if not set via CLI
        if [[ -z "$PACKAGE_TIER" ]]; then
            PACKAGE_TIER=$(grep "^package:" "$config_file" | cut -d: -f2 | tr -d ' "' || echo "standard")
        fi

        # Read skip_dotfiles preference
        if grep -q "skip_dotfiles: true" "$config_file"; then
            SKIP_DOTFILES=true
        fi

        log_success "User config loaded"
    elif [[ "$USE_CONFIG" == true ]]; then
        log_warning "User config not found: $config_file"
        log_info "Copy the example: cp config/user-config.yaml.example config/user-config.yaml"
    fi
}

# Check if tool should be excluded
should_exclude() {
    local tool="$1"
    local config_file="${SCRIPT_DIR}/config/user-config.yaml"

    if [[ -f "$config_file" ]]; then
        if grep -A 100 "^exclude:" "$config_file" 2>/dev/null | grep -q "^\s*- $tool\s*$"; then
            log_info "Excluding (per user config): $tool"
            return 0
        fi
    fi

    return 1
}

# Confirmation prompt
confirm_installation() {
    if [[ "$AUTO_YES" == true ]]; then
        return 0
    fi

    echo ""
    log_warning "This script will install development tools on your Mac."
    log_warning "Package tier: $PACKAGE_TIER"
    log_warning "Existing dotfiles will be backed up before modification."
    echo ""
    read -p "Do you want to continue? [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            log_info "Installation cancelled."
            exit 0
            ;;
    esac
}

# Run a module script
run_module() {
    local module_name="$1"
    local module_path="${SCRIPT_DIR}/modules/${module_name}"

    if [[ ! -f "$module_path" ]]; then
        log_warning "Module not found: $module_name"
        return 1
    fi

    log_section "Running: $module_name"

    # Source and run module
    if bash "$module_path"; then
        log_success "Completed: $module_name"
        return 0
    else
        log_error "Failed: $module_name"
        return 1
    fi
}

# Main installation function
main() {
    # Handle --show-packages early
    parse_args "$@"

    if [[ "$SHOW_PACKAGES" == true ]]; then
        show_package_contents
        exit 0
    fi

    # Initialize
    clear
    print_banner

    # Setup logging
    mkdir -p "${SCRIPT_DIR}/logs"
    LOG_FILE="${SCRIPT_DIR}/logs/install-$(date +%Y%m%d-%H%M%S).log"
    exec > >(tee -a "$LOG_FILE") 2>&1

    log_info "Installation log: $LOG_FILE"

    # Load user config
    load_user_config

    # Check macOS
    log_section "System Check"
    check_macos
    check_architecture
    check_disk_space
    check_internet

    # Select package
    select_package

    # Confirm
    confirm_installation

    # Initialize state tracking
    init_state

    # Export variables for modules
    export SCRIPT_DIR
    export PACKAGE_TIER
    export AUTO_YES
    export SKIP_DOTFILES
    export LOG_FILE
    export STATE_FILE

    # Run installation modules based on package tier
    log_section "Starting Installation ($PACKAGE_TIER)"

    # System essentials (always required)
    run_module "01-system-essentials.sh"

    # Package-based installation
    case $PACKAGE_TIER in
        light)
            run_module "02-dev-tools.sh"
            run_module "03-languages.sh"
            run_module "05-cli-tools.sh"
            run_module "09-browsers.sh"
            ;;
        standard)
            run_module "02-dev-tools.sh"
            run_module "03-languages.sh"
            run_module "04-devops-tools.sh"
            run_module "05-cli-tools.sh"
            run_module "09-browsers.sh"
            run_module "10-databases.sh"
            run_module "07-communication.sh"
            run_module "11-optional-apps.sh"
            ;;
        advanced)
            run_module "02-dev-tools.sh"
            run_module "03-languages.sh"
            run_module "04-devops-tools.sh"
            run_module "05-cli-tools.sh"
            run_module "06-network-tools.sh"
            run_module "07-communication.sh"
            run_module "08-ai-tools.sh"
            run_module "09-browsers.sh"
            run_module "10-databases.sh"
            run_module "11-optional-apps.sh"
            ;;
    esac

    # Configure dotfiles
    if [[ "$SKIP_DOTFILES" != true ]]; then
        log_section "Configuring Dotfiles"
        configure_dotfiles
    fi

    # Save installation state
    log_section "Saving Installation State"
    save_state_summary
    update_state_timestamp

    # Validation
    log_section "Validation"
    if [[ -f "${SCRIPT_DIR}/tests/validate.sh" ]]; then
        bash "${SCRIPT_DIR}/tests/validate.sh" --quick
    fi

    # Complete
    log_section "Installation Complete"
    print_summary
}

# Print banner
print_banner() {
    echo ""
    echo "=================================================================="
    echo "     Mac Dev Machine Setup"
    echo "     https://github.com/devopz-ai/Mac-dev-machine"
    echo "=================================================================="
    echo ""
}

# Print summary
print_summary() {
    echo ""
    log_success "Installation completed successfully!"
    echo ""
    echo "Package installed: $PACKAGE_TIER"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Configure Git with your credentials:"
    echo "     git config --global user.name \"Your Name\""
    echo "     git config --global user.email \"you@example.com\""
    echo ""
    echo "Useful commands:"
    echo "  ./tests/validate.sh       # Verify installation"
    echo "  ./update.sh               # Update all tools"
    echo "  ./uninstall.sh --list     # List installed tools"
    echo "  ./uninstall.sh --tool X   # Remove a specific tool"
    echo ""
    echo "State file: $STATE_FILE"
    echo "Log file: $LOG_FILE"
    echo ""
}

# Configure dotfiles
configure_dotfiles() {
    local dotfiles_dir="${SCRIPT_DIR}/config/dotfiles"
    local timestamp=$(date +%Y%m%d-%H%M%S)

    # Backup and configure .zshrc
    if [[ -f "${dotfiles_dir}/.zshrc.template" ]]; then
        if [[ -f "$HOME/.zshrc" ]]; then
            log_info "Backing up existing .zshrc"
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup.${timestamp}"
        fi

        log_info "Configuring .zshrc"
        if [[ -f "$HOME/.zshrc" ]]; then
            if ! grep -q "# Mac Dev Machine Setup" "$HOME/.zshrc"; then
                cat "${dotfiles_dir}/.zshrc.template" >> "$HOME/.zshrc"
            fi
        else
            cp "${dotfiles_dir}/.zshrc.template" "$HOME/.zshrc"
        fi
    fi

    # Backup and configure .gitconfig
    if [[ -f "${dotfiles_dir}/.gitconfig.template" ]]; then
        if [[ -f "$HOME/.gitconfig" ]]; then
            log_info "Backing up existing .gitconfig"
            cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup.${timestamp}"
        fi

        if [[ ! -f "$HOME/.gitconfig" ]]; then
            log_info "Creating .gitconfig template"
            cp "${dotfiles_dir}/.gitconfig.template" "$HOME/.gitconfig"
        else
            log_info "Existing .gitconfig found, skipping (configure manually)"
        fi
    fi

    # Configure .vimrc
    if [[ -f "${dotfiles_dir}/.vimrc.template" ]]; then
        if [[ -f "$HOME/.vimrc" ]]; then
            log_info "Backing up existing .vimrc"
            cp "$HOME/.vimrc" "$HOME/.vimrc.backup.${timestamp}"
        fi

        if [[ ! -f "$HOME/.vimrc" ]]; then
            log_info "Creating .vimrc"
            cp "${dotfiles_dir}/.vimrc.template" "$HOME/.vimrc"
        fi
    fi

    log_success "Dotfiles configured"
}

# Run main
main "$@"
