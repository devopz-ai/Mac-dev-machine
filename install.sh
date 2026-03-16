#!/bin/bash
#
# Mac Dev Machine Setup - Main Installation Script
# https://github.com/devopz-ai/Mac-dev-machine
#
# Copyright (c) 2024-2026 Devopz.ai
# Author: Rashed Ahmed <rashed.ahmed@devopz.ai>
# License: MIT
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

# Get version from VERSION file
get_version() {
    local version_file="${SCRIPT_DIR}/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file" | tr -d '\n'
    else
        echo "unknown"
    fi
}

# Show version
show_version() {
    local version=$(get_version)
    echo "Mac Dev Machine v${version}"
    echo "Copyright (c) 2024-2026 Devopz.ai"
    echo "Author: Rashed Ahmed <rashed.ahmed@devopz.ai>"
    echo "License: MIT"
    echo ""
    echo "https://github.com/devopz-ai/Mac-dev-machine"
}

# Default values
PACKAGE_TIER=""
AUTO_YES=false
SKIP_DOTFILES=false
USE_CONFIG=false
SHOW_PACKAGES=false
LOG_FILE=""
STATE_FILE="$HOME/.mac-dev-machine-state.yaml"
CONFIG_FILE="$HOME/.mac-dev-machine/config.txt"  # Tracks installation settings
SUDO_PASSWORD="${SUDO_PASSWORD:-}"  # Can be set via environment variable
SUDO_KEEPALIVE_PID=""
EXCLUDED_CATEGORIES=""  # Comma-separated list of categories to exclude
ONLY_CATEGORIES=""      # Comma-separated list of categories to install (add mode)
ADD_TOOLS=""            # Comma-separated list of specific tools to install

# Available categories for exclusion/inclusion
VALID_CATEGORIES="terminal,editors,languages,git,devops,virtualization,cli,network,ai,databases,browsers,communication,apps"

# If SUDO_PASSWORD is set via env, enable auto-yes
if [[ -n "$SUDO_PASSWORD" ]]; then
    AUTO_YES=true
fi

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
            --sudo-pass|-P)
                SUDO_PASSWORD="$2"
                AUTO_YES=true  # Auto-yes when password provided for full automation
                shift 2
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
            --exclude|-e)
                EXCLUDED_CATEGORIES="$2"
                shift 2
                ;;
            --only|-o)
                ONLY_CATEGORIES="$2"
                shift 2
                ;;
            --add|-a)
                ADD_TOOLS="$2"
                shift 2
                ;;
            --show-categories)
                show_categories
                exit 0
                ;;
            --scan|-s)
                run_scan
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
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

# Run scan for installed packages
run_scan() {
    local scan_script="${SCRIPT_DIR}/scan-installed.sh"

    if [[ ! -f "$scan_script" ]]; then
        log_error "scan-installed.sh not found"
        exit 1
    fi

    # Count packages to estimate time
    local formula_count=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    local cask_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    local npm_count=$(npm list -g --depth=0 2>/dev/null | grep -c "├──\|└──" || echo 0)
    local pip_count=$(pip3 list 2>/dev/null | tail -n +3 | wc -l | tr -d ' ')
    local total=$((formula_count + cask_count + npm_count + pip_count))

    # Estimate time (~0.5s per package)
    local est_seconds=$((total / 2))
    local est_time=""
    if [[ $est_seconds -lt 60 ]]; then
        est_time="${est_seconds}s"
    else
        est_time="$((est_seconds / 60))m $((est_seconds % 60))s"
    fi

    echo ""
    echo -e "${CYAN}Package Scan${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Found packages to scan:"
    echo "    Homebrew Formulas: $formula_count"
    echo "    Homebrew Casks:    $cask_count"
    echo "    NPM Packages:      $npm_count"
    echo "    Pip Packages:      $pip_count"
    echo "    ─────────────────────"
    echo "    Total:             $total"
    echo ""
    echo -e "  ${YELLOW}Estimated time: ~${est_time}${NC}"
    echo ""

    read -p "Start scan? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo ""
        "$scan_script" -r
    else
        log_info "Scan cancelled"
    fi
}

# Initialize sudo with password (for full automation)
init_sudo() {
    if [[ -n "$SUDO_PASSWORD" ]]; then
        log_step "Authenticating sudo..."

        # Create a helper script for SUDO_ASKPASS
        SUDO_ASKPASS_SCRIPT=$(mktemp)
        chmod 700 "$SUDO_ASKPASS_SCRIPT"
        cat > "$SUDO_ASKPASS_SCRIPT" << ASKPASS_EOF
#!/bin/bash
echo "$SUDO_PASSWORD"
ASKPASS_EOF
        export SUDO_ASKPASS="$SUDO_ASKPASS_SCRIPT"
        export HOMEBREW_SUDO_ASKPASS="$SUDO_ASKPASS_SCRIPT"

        # Test sudo authentication
        if echo "$SUDO_PASSWORD" | sudo -S -v 2>/dev/null; then
            log_success "Sudo authenticated"
            # Start background process to keep sudo alive
            start_sudo_keepalive
        else
            log_error "Sudo authentication failed. Check your password."
            rm -f "$SUDO_ASKPASS_SCRIPT"
            exit 1
        fi
    else
        # Traditional sudo - will prompt if needed
        if ! sudo -v 2>/dev/null; then
            log_warning "Some installations may require sudo password"
        fi
    fi
}

# Keep sudo alive in background
start_sudo_keepalive() {
    if [[ -n "$SUDO_PASSWORD" ]]; then
        (
            while true; do
                echo "$SUDO_PASSWORD" | sudo -S -v 2>/dev/null
                sleep 30  # Refresh more frequently
            done
        ) &
        SUDO_KEEPALIVE_PID=$!
        # Ensure cleanup on exit
        trap cleanup_sudo EXIT
    fi
}

# Cleanup sudo keepalive process
cleanup_sudo() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
    # Remove askpass script
    if [[ -n "$SUDO_ASKPASS_SCRIPT" ]] && [[ -f "$SUDO_ASKPASS_SCRIPT" ]]; then
        rm -f "$SUDO_ASKPASS_SCRIPT"
    fi
    # Invalidate sudo timestamp
    sudo -k 2>/dev/null || true
}

# Run command with sudo using stored password
run_sudo() {
    if [[ -n "$SUDO_PASSWORD" ]]; then
        echo "$SUDO_PASSWORD" | sudo -S "$@" 2>/dev/null
    else
        sudo "$@"
    fi
}

# Show available categories for exclusion
show_categories() {
    echo ""
    echo -e "${BLUE}Available Categories for Exclusion${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
    echo -e "${CYAN}Category        What's Included${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    echo -e "${GREEN}terminal${NC}        iTerm2, tmux, Starship, Warp, Alacritty, Kitty"
    echo -e "${GREEN}editors${NC}         VS Code, Cursor, Neovim, PyCharm, IntelliJ, Zed, Sublime"
    echo -e "${GREEN}languages${NC}       Python, Node.js, Go, Java, Rust, Ruby, Bun, Deno"
    echo -e "${GREEN}git${NC}             Git, GitHub CLI, GitLab CLI, lazygit, git-delta"
    echo -e "${GREEN}devops${NC}          Docker, kubectl, Helm, Terraform, Ansible, cloud CLIs"
    echo -e "${GREEN}virtualization${NC}  VirtualBox, Vagrant, UTM, QEMU, Lima, Colima, Podman"
    echo -e "${GREEN}cli${NC}             jq, bat, ripgrep, fzf, eza, fd, htop, wget, httpie"
    echo -e "${GREEN}network${NC}         Wireshark, nmap, mitmproxy, mkcert, ngrok"
    echo -e "${GREEN}ai${NC}              Ollama, LM Studio, GPT4All, LangChain, Aider, llama.cpp"
    echo -e "${GREEN}databases${NC}       PostgreSQL, Redis, MySQL, DBeaver, TablePlus, MongoDB"
    echo -e "${GREEN}browsers${NC}        Chrome, Firefox, Brave, Arc, Safari (system)"
    echo -e "${GREEN}communication${NC}   Slack, Discord, Zoom, Teams, WhatsApp, Telegram"
    echo -e "${GREEN}apps${NC}            Rectangle, Postman, Notion, Obsidian, Raycast, Alfred"
    echo ""
    echo -e "${CYAN}Exclude during install:${NC}"
    echo "  ./install.sh --package standard --exclude ai"
    echo "  ./install.sh --package standard --exclude ai,communication"
    echo ""
    echo -e "${CYAN}Add categories later (--only mode):${NC}"
    echo "  ./install.sh --package standard --only ai          # Add just AI tools"
    echo "  ./install.sh --package advanced --only ai,network  # Add AI + network tools"
    echo ""

    echo -e "${CYAN}Add specific tools by name:${NC}"
    echo "  ./install.sh --add ollama                  # Single tool"
    echo "  ./install.sh --add ollama,lm-studio,jan   # Multiple tools"
    echo "  ./install.sh --add some-unknown-tool      # Auto-detect & install"
    echo ""

    # Show previous exclusions if any
    if [[ -f "$HOME/.mac-dev-machine/config.txt" ]]; then
        local prev_excluded=$(grep "^excluded=" "$HOME/.mac-dev-machine/config.txt" 2>/dev/null | cut -d= -f2)
        local prev_package=$(grep "^package=" "$HOME/.mac-dev-machine/config.txt" 2>/dev/null | cut -d= -f2)
        if [[ -n "$prev_excluded" ]]; then
            echo -e "${YELLOW}Previously excluded categories:${NC} $prev_excluded"
            echo -e "${YELLOW}Package tier:${NC} $prev_package"
            echo ""
            echo -e "${GREEN}To add these now:${NC}"
            echo "  ./install.sh --package $prev_package --only $prev_excluded"
            echo ""
        fi
    fi

    # Show custom tools if any
    if [[ -f "$HOME/.mac-dev-machine/custom-tools.txt" ]] && [[ -s "$HOME/.mac-dev-machine/custom-tools.txt" ]]; then
        echo -e "${CYAN}Custom tools (installed outside predefined list):${NC}"
        cat "$HOME/.mac-dev-machine/custom-tools.txt" | tr '\n' ', ' | sed 's/,$/\n/'
        echo ""
    fi
}

# Check if category is excluded
is_category_excluded() {
    local category="$1"

    # In --only mode, exclude everything NOT in the only list
    if [[ -n "$ONLY_CATEGORIES" ]]; then
        if echo ",$ONLY_CATEGORIES," | grep -q ",$category,"; then
            return 1  # Not excluded (it's in the only list)
        else
            return 0  # Excluded (not in the only list)
        fi
    fi

    # Normal exclude mode
    if [[ -z "$EXCLUDED_CATEGORIES" ]]; then
        return 1  # Not excluded
    fi
    echo ",$EXCLUDED_CATEGORIES," | grep -q ",$category,"
}

# Save installation config to file
save_install_config() {
    local config_dir="$HOME/.mac-dev-machine"
    mkdir -p "$config_dir"

    cat > "$CONFIG_FILE" << EOF
# Mac Dev Machine Installation Config
# Generated: $(date)
package=$PACKAGE_TIER
excluded=$EXCLUDED_CATEGORIES
install_date=$(date +%Y-%m-%d_%H:%M:%S)
EOF
    log_info "Installation config saved to $CONFIG_FILE"
}

# Load previous installation config
load_install_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        local prev_package=$(grep "^package=" "$CONFIG_FILE" | cut -d= -f2)
        local prev_excluded=$(grep "^excluded=" "$CONFIG_FILE" | cut -d= -f2)
        echo "package:$prev_package"
        echo "excluded:$prev_excluded"
    fi
}

# Get previously excluded categories
get_previous_exclusions() {
    if [[ -f "$CONFIG_FILE" ]]; then
        grep "^excluded=" "$CONFIG_FILE" | cut -d= -f2
    fi
}

# Get previous package tier
get_previous_package() {
    if [[ -f "$CONFIG_FILE" ]]; then
        grep "^package=" "$CONFIG_FILE" | cut -d= -f2
    fi
}

# Check if tool is a known formula
is_known_formula() {
    local tool="$1"
    local all_formulas="git gh pyenv nvm neovim jq bat ripgrep fzf htop git-lfs glab lazygit git-delta tmux starship go rustup-init maven gradle kubectl helm terraform yq eza fd zoxide wget httpie tree postgresql@16 redis vagrant packer rbenv ruby-build bun deno tig git-flow k9s kubectx minikube kind terragrunt tflint ansible awscli azure-cli pulumi trivy telnet nmap mtr mitmproxy mkcert mysql sqlite ffmpeg imagemagick btop ncdu tldr thefuck shellcheck chromedriver geckodriver qemu lima colima podman ollama llama.cpp huggingface-cli qdrant milvus"
    echo " $all_formulas " | grep -q " $tool "
}

# Check if tool is a known cask
is_known_cask() {
    local tool="$1"
    local all_casks="iterm2 visual-studio-code google-chrome firefox virtualbox cursor pycharm-ce docker brave-browser dbeaver-community slack discord zoom rectangle postman the-unarchiver temurin multipass intellij-idea-ce jetbrains-toolbox goland webstorm datagrip zed sublime-text warp alacritty kitty lens google-cloud-sdk firefox-developer-edition arc chromium tor-browser opera wireshark ngrok lm-studio gpt4all jan msty mongodb-compass tableplus pgadmin4 microsoft-teams whatsapp telegram signal raycast alfred notion obsidian insomnia bruno vlc bitwarden keepassxc stats hiddenbar monitorcontrol appcleaner utm diffusionbee drawthings"
    echo " $all_casks " | grep -q " $tool "
}

# Check if tool exists in Homebrew
check_brew_exists() {
    local tool="$1"
    # Check if formula exists
    if brew info "$tool" &>/dev/null 2>&1; then
        echo "formula"
        return 0
    fi
    # Check if cask exists
    if brew info --cask "$tool" &>/dev/null 2>&1; then
        echo "cask"
        return 0
    fi
    return 1
}

# Ask user for installation method when tool not found
ask_install_method() {
    local tool="$1"

    echo ""
    echo -e "${YELLOW}Tool '$tool' not found in Homebrew.${NC}"
    echo ""
    echo "How would you like to install it?"
    echo ""
    echo "  1) Homebrew tap (e.g., user/repo)"
    echo "  2) URL download (curl/wget)"
    echo "  3) pip install (Python package)"
    echo "  4) npm install (Node package)"
    echo "  5) Custom command"
    echo "  6) Skip this tool"
    echo ""

    read -p "Choose [1-6]: " choice

    case $choice in
        1)
            read -p "Enter tap name (e.g., user/repo): " tap_name
            if [[ -n "$tap_name" ]]; then
                echo "tap:$tap_name"
            else
                echo "skip"
            fi
            ;;
        2)
            read -p "Enter download URL: " url
            if [[ -n "$url" ]]; then
                echo "url:$url"
            else
                echo "skip"
            fi
            ;;
        3)
            read -p "Enter pip package name (or press Enter for '$tool'): " pkg
            echo "pip:${pkg:-$tool}"
            ;;
        4)
            read -p "Enter npm package name (or press Enter for '$tool'): " pkg
            echo "npm:${pkg:-$tool}"
            ;;
        5)
            read -p "Enter custom install command: " cmd
            if [[ -n "$cmd" ]]; then
                echo "custom:$cmd"
            else
                echo "skip"
            fi
            ;;
        6|*)
            echo "skip"
            ;;
    esac
}

# Install tool via URL
install_via_url() {
    local tool="$1"
    local url="$2"
    local download_dir="$HOME/.mac-dev-machine/downloads"
    mkdir -p "$download_dir"

    local filename=$(basename "$url")
    local filepath="$download_dir/$filename"

    log_step "Downloading from $url..."

    if curl -fsSL "$url" -o "$filepath"; then
        # Detect file type and install accordingly
        case "$filename" in
            *.pkg)
                log_step "Installing .pkg file..."
                sudo installer -pkg "$filepath" -target /
                ;;
            *.dmg)
                log_step "Mounting .dmg file..."
                local mount_point=$(hdiutil attach "$filepath" | grep "/Volumes" | awk '{print $3}')
                if [[ -n "$mount_point" ]]; then
                    # Look for .app or .pkg inside
                    local app=$(find "$mount_point" -maxdepth 1 -name "*.app" | head -1)
                    local pkg=$(find "$mount_point" -maxdepth 1 -name "*.pkg" | head -1)
                    if [[ -n "$app" ]]; then
                        cp -R "$app" /Applications/
                        log_success "Copied $(basename "$app") to Applications"
                    elif [[ -n "$pkg" ]]; then
                        sudo installer -pkg "$pkg" -target /
                    fi
                    hdiutil detach "$mount_point" -quiet
                fi
                ;;
            *.zip)
                log_step "Extracting .zip file..."
                unzip -o "$filepath" -d "$download_dir"
                local app=$(find "$download_dir" -maxdepth 2 -name "*.app" | head -1)
                if [[ -n "$app" ]]; then
                    cp -R "$app" /Applications/
                    log_success "Copied $(basename "$app") to Applications"
                fi
                ;;
            *.tar.gz|*.tgz)
                log_step "Extracting tarball..."
                tar -xzf "$filepath" -C "$download_dir"
                log_info "Extracted to $download_dir"
                ;;
            *.sh)
                log_step "Running install script..."
                chmod +x "$filepath"
                bash "$filepath"
                ;;
            *)
                # Assume it's a binary
                chmod +x "$filepath"
                sudo mv "$filepath" /usr/local/bin/"$tool"
                log_success "Installed binary to /usr/local/bin/$tool"
                ;;
        esac
        return 0
    else
        log_error "Download failed"
        return 1
    fi
}

# Install specific tools (--add mode)
install_specific_tools() {
    local tools="$1"
    local state_dir="$HOME/.mac-dev-machine"
    local state_file="$state_dir/installed.txt"
    local custom_file="$state_dir/custom-tools.txt"
    local timestamp=$(date +%Y-%m-%d_%H:%M:%S)

    mkdir -p "$state_dir"
    touch "$custom_file"

    log_section "Installing Specific Tools"
    echo ""

    # Convert comma-separated to space-separated
    local tool_list=$(echo "$tools" | tr ',' ' ')
    local total=$(echo "$tool_list" | wc -w | tr -d ' ')
    local current=0
    local installed=0
    local failed=0
    local skipped=0

    for tool in $tool_list; do
        ((current++))
        echo -e "${CYAN}[$current/$total]${NC} Processing: ${BLUE}$tool${NC}"

        local install_type=""
        local success=false

        # Check if already installed
        if brew list "$tool" &>/dev/null 2>&1; then
            log_info "$tool is already installed (formula)"
            install_type="formula"
            success=true
        elif brew list --cask "$tool" &>/dev/null 2>&1; then
            log_info "$tool is already installed (cask)"
            install_type="cask"
            success=true
        elif command -v "$tool" &>/dev/null; then
            log_info "$tool is already installed (found in PATH)"
            install_type="system"
            success=true
        else
            # Check if it's a known tool
            if is_known_formula "$tool"; then
                log_step "Installing $tool (formula)..."
                if brew install "$tool"; then
                    install_type="formula"
                    success=true
                fi
            elif is_known_cask "$tool"; then
                log_step "Installing $tool (cask)..."
                if brew install --cask "$tool"; then
                    install_type="cask"
                    success=true
                fi
            else
                # Unknown tool - check if it exists in Homebrew
                local brew_type=$(check_brew_exists "$tool")

                if [[ -n "$brew_type" ]]; then
                    log_step "Installing $tool ($brew_type)..."
                    if [[ "$brew_type" == "formula" ]]; then
                        brew install "$tool" && success=true && install_type="formula"
                    else
                        brew install --cask "$tool" && success=true && install_type="cask"
                    fi

                    if $success; then
                        # Track as custom tool
                        if ! grep -q "^$tool|" "$custom_file" 2>/dev/null; then
                            echo "$tool|$brew_type|$timestamp" >> "$custom_file"
                        fi
                    fi
                else
                    # Not in Homebrew - ask user what to do
                    local method=$(ask_install_method "$tool")
                    local method_type=$(echo "$method" | cut -d: -f1)
                    local method_value=$(echo "$method" | cut -d: -f2-)

                    case "$method_type" in
                        tap)
                            log_step "Adding tap: $method_value"
                            if brew tap "$method_value" && brew install "$tool"; then
                                install_type="formula"
                                success=true
                                echo "$tool|tap:$method_value|$timestamp" >> "$custom_file"
                            fi
                            ;;
                        url)
                            if install_via_url "$tool" "$method_value"; then
                                install_type="url"
                                success=true
                                echo "$tool|url:$method_value|$timestamp" >> "$custom_file"
                            fi
                            ;;
                        pip)
                            log_step "Installing via pip: $method_value"
                            if pip3 install "$method_value"; then
                                install_type="pip"
                                success=true
                                echo "$tool|pip:$method_value|$timestamp" >> "$custom_file"
                            fi
                            ;;
                        npm)
                            log_step "Installing via npm: $method_value"
                            if npm install -g "$method_value"; then
                                install_type="npm"
                                success=true
                                echo "$tool|npm:$method_value|$timestamp" >> "$custom_file"
                            fi
                            ;;
                        custom)
                            log_step "Running custom command..."
                            if eval "$method_value"; then
                                install_type="custom"
                                success=true
                                echo "$tool|custom:$method_value|$timestamp" >> "$custom_file"
                            fi
                            ;;
                        skip)
                            log_info "Skipped $tool"
                            ((skipped++))
                            echo ""
                            continue
                            ;;
                    esac
                fi
            fi
        fi

        if $success; then
            log_success "$tool installed ($install_type)"
            ((installed++))
            # Record in state file
            if ! grep -q "^${install_type}|${tool}|" "$state_file" 2>/dev/null; then
                echo "${install_type}|${tool}|${tool}|${timestamp}" >> "$state_file"
            fi
        else
            log_error "Failed to install $tool"
            ((failed++))
        fi
        echo ""
    done

    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Installation Summary${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}Installed:${NC} $installed"
    echo -e "  ${YELLOW}Skipped:${NC}   $skipped"
    echo -e "  ${RED}Failed:${NC}    $failed"
    echo ""

    if [[ -s "$custom_file" ]]; then
        echo -e "  ${CYAN}Custom tools tracked in:${NC} $custom_file"
        echo ""
    fi
}

show_help() {
    echo ""
    echo -e "${BLUE}Mac Dev Machine Setup${NC}"
    echo -e "${BLUE}=====================${NC}"
    echo ""
    echo "Automated setup for macOS development machines."
    echo "Installs dev tools, languages, DevOps tools, and more."
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  ./install.sh [OPTIONS]"
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo "  --package, -p <tier>   Package tier: light, standard, advanced"
    echo "  --exclude, -e <cats>   Exclude categories (comma-separated)"
    echo "  --only, -o <cats>      Install ONLY these categories (add mode)"
    echo "  --add, -a <tools>      Install specific tools by name"
    echo "  --yes, -y              Non-interactive mode, accept all defaults"
    echo "  --sudo-pass, -P <pwd>  Sudo password for full automation (implies --yes)"
    echo "  --config, -c           Use config/user-config.yaml for customization"
    echo "  --skip-dotfiles        Skip dotfiles configuration"
    echo "  --show-packages        Show what's included in each package tier"
    echo "  --show-categories      Show available categories for exclusion"
    echo "  --scan, -s             Scan and record installed packages"
    echo "  --version, -v          Show version information"
    echo "  --help, -h             Show this help message"
    echo ""
    echo -e "${CYAN}Package Tiers:${NC}"
    echo -e "  ${GREEN}light${NC}      Essential tools only (~15 min, ~5GB)"
    echo "             VS Code, Python, Node.js, Git, Chrome, Firefox"
    echo ""
    echo -e "  ${YELLOW}standard${NC}   Recommended for most developers (~30 min, ~15GB)"
    echo "             + Cursor, Go, Java, Rust, Docker, Terraform, PostgreSQL"
    echo ""
    echo -e "  ${RED}advanced${NC}   Everything for power users (~60 min, ~30GB)"
    echo "             + AI tools, Wireshark, all cloud CLIs, all databases"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  ./install.sh --show-packages        # See what's in each package"
    echo "  ./install.sh --show-categories      # See categories for exclusion"
    echo "  ./install.sh --package light        # Minimal installation"
    echo "  ./install.sh --package standard     # Recommended installation"
    echo "  ./install.sh --package advanced -y  # Full install, non-interactive"
    echo ""
    echo -e "${CYAN}Exclude Categories:${NC}"
    echo "  ./install.sh --package standard --exclude ai"
    echo "  ./install.sh --package standard --exclude ai,communication"
    echo "  ./install.sh --package advanced --exclude ai,virtualization,browsers"
    echo ""
    echo -e "${CYAN}Add Categories Later (--only mode):${NC}"
    echo "  ./install.sh --package standard --only ai        # Add AI tools"
    echo "  ./install.sh --package advanced --only ai,network # Add AI + network"
    echo ""
    echo -e "${CYAN}Add Specific Tools (--add mode):${NC}"
    echo "  ./install.sh --add ollama                  # Add single tool"
    echo "  ./install.sh --add ollama,lm-studio,jan   # Add multiple tools"
    echo "  ./install.sh --add some-new-tool          # Auto-detect & install"
    echo ""
    echo -e "${CYAN}Full Automation (no prompts):${NC}"
    echo "  ./install.sh --package standard --sudo-pass \"yourpassword\""
    echo ""
    echo -e "${YELLOW}Security Note:${NC}"
    echo "  --sudo-pass is visible in process lists. For better security, use:"
    echo "  export SUDO_PASSWORD=\"password\" && ./install.sh --package standard"
    echo ""
    echo -e "${CYAN}Other Scripts:${NC}"
    echo "  ./uninstall.sh         # Remove installed tools"
    echo "  ./scan-installed.sh    # Scan and record installed packages"
    echo "  ./update.sh            # Update installed tools"
    echo ""
    echo -e "${CYAN}More Info:${NC}"
    echo "  State file: ~/.mac-dev-machine/installed.txt"
    echo "  Docs: https://github.com/devopz-ai/Mac-dev-machine"
    echo ""
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
    echo -e "${CYAN}Virtualization:${NC}"
    echo "  - VirtualBox (Oracle, open source)"
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
    echo "  - Packer (machine images)"
    echo ""
    echo -e "${CYAN}Virtualization:${NC}"
    echo "  - Vagrant (VM management)"
    echo "  - Multipass (Ubuntu VMs)"
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
    echo -e "${CYAN}Virtualization (Advanced):${NC}"
    echo "  - UTM (Apple Silicon native, QEMU-based)"
    echo "  - QEMU (low-level emulator)"
    echo "  - Lima (Linux VMs for Mac)"
    echo "  - Colima (container runtimes)"
    echo "  - Podman (Docker alternative)"
    echo ""
    echo -e "${CYAN}AI & LLM Tools (Local):${NC}"
    echo "  - Ollama (local LLM runtime)"
    echo "  - LM Studio (LLM GUI)"
    echo "  - GPT4All (offline LLMs)"
    echo "  - Jan (local AI assistant)"
    echo "  - llama.cpp (Metal accelerated)"
    echo "  - DiffusionBee (Stable Diffusion)"
    echo "  - Draw Things (AI image gen)"
    echo ""
    echo -e "${CYAN}AI Development:${NC}"
    echo "  - Aider (AI pair programming)"
    echo "  - Open Interpreter"
    echo "  - Shell GPT"
    echo "  - LiteLLM (unified API)"
    echo "  - LangChain, LlamaIndex"
    echo "  - Hugging Face CLI"
    echo "  - OpenAI, Anthropic SDKs"
    echo ""
    echo -e "${CYAN}Vector Databases:${NC}"
    echo "  - Qdrant"
    echo "  - Milvus"
    echo "  - ChromaDB (pip)"
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

# Define category mappings for formulas
get_formula_category() {
    local formula="$1"
    case "$formula" in
        # terminal
        tmux|starship) echo "terminal" ;;
        # editors
        neovim) echo "editors" ;;
        # languages
        pyenv|nvm|go|rustup-init|maven|gradle|rbenv|ruby-build|bun|deno) echo "languages" ;;
        # git
        git|gh|git-lfs|glab|lazygit|git-delta|tig|git-flow) echo "git" ;;
        # devops
        kubectl|helm|terraform|k9s|kubectx|minikube|kind|terragrunt|tflint|ansible|awscli|azure-cli|pulumi|trivy|packer) echo "devops" ;;
        # virtualization
        vagrant|qemu|lima|colima|podman) echo "virtualization" ;;
        # cli
        jq|bat|ripgrep|fzf|htop|yq|eza|fd|zoxide|wget|httpie|tree|ffmpeg|imagemagick|btop|ncdu|tldr|thefuck|shellcheck|chromedriver|geckodriver) echo "cli" ;;
        # network
        telnet|nmap|mtr|mitmproxy|mkcert) echo "network" ;;
        # ai
        ollama|llama.cpp|huggingface-cli|qdrant|milvus) echo "ai" ;;
        # databases
        postgresql@16|redis|mysql|sqlite) echo "databases" ;;
        *) echo "system" ;;  # Default category (never excluded)
    esac
}

# Define package lists
get_package_formulas() {
    local tier="$1"
    local formulas=""
    local all_formulas=""

    # Light tier formulas
    local light_formulas="git gh pyenv nvm neovim jq bat ripgrep fzf htop"

    # Standard tier adds these (includes vagrant for VM management, packer for images)
    local standard_formulas="git-lfs glab lazygit git-delta tmux starship go rustup-init maven gradle kubectl helm terraform yq eza fd zoxide wget httpie tree postgresql@16 redis vagrant packer"

    # Advanced tier adds these (includes virtualization and AI/ML tools)
    local advanced_formulas="rbenv ruby-build bun deno tig git-flow k9s kubectx minikube kind terragrunt tflint ansible awscli azure-cli pulumi trivy telnet nmap mtr mitmproxy mkcert mysql sqlite ffmpeg imagemagick btop ncdu tldr thefuck shellcheck chromedriver geckodriver qemu lima colima podman ollama llama.cpp huggingface-cli qdrant milvus"

    case "$tier" in
        light) all_formulas="$light_formulas" ;;
        standard) all_formulas="$light_formulas $standard_formulas" ;;
        advanced) all_formulas="$light_formulas $standard_formulas $advanced_formulas" ;;
    esac

    # Filter out excluded categories
    for formula in $all_formulas; do
        local category=$(get_formula_category "$formula")
        if ! is_category_excluded "$category"; then
            formulas="$formulas $formula"
        fi
    done

    echo "$formulas"
}

# Define category mappings for casks
get_cask_category() {
    local cask="$1"
    case "$cask" in
        # terminal
        iterm2|warp|alacritty|kitty) echo "terminal" ;;
        # editors
        visual-studio-code|cursor|pycharm-ce|intellij-idea-ce|jetbrains-toolbox|goland|webstorm|datagrip|zed|sublime-text) echo "editors" ;;
        # languages (runtime installers)
        temurin) echo "languages" ;;
        # devops
        docker|lens|google-cloud-sdk) echo "devops" ;;
        # virtualization
        virtualbox|multipass|utm) echo "virtualization" ;;
        # network
        wireshark|ngrok) echo "network" ;;
        # ai
        lm-studio|gpt4all|jan|msty|diffusionbee|drawthings) echo "ai" ;;
        # databases
        dbeaver-community|mongodb-compass|tableplus|pgadmin4) echo "databases" ;;
        # browsers
        google-chrome|firefox|brave-browser|firefox-developer-edition|arc|chromium|tor-browser|opera) echo "browsers" ;;
        # communication
        slack|discord|zoom|microsoft-teams|whatsapp|telegram|signal) echo "communication" ;;
        # apps
        rectangle|postman|the-unarchiver|raycast|alfred|notion|obsidian|insomnia|bruno|vlc|bitwarden|keepassxc|stats|hiddenbar|monitorcontrol|appcleaner) echo "apps" ;;
        *) echo "system" ;;  # Default category (never excluded)
    esac
}

get_package_casks() {
    local tier="$1"
    local casks=""
    local all_casks=""

    # Light tier casks (includes virtualbox for VM support in all tiers)
    local light_casks="iterm2 visual-studio-code google-chrome firefox virtualbox"

    # Standard tier adds these (includes multipass for quick VMs)
    local standard_casks="cursor pycharm-ce docker brave-browser dbeaver-community slack discord zoom rectangle postman the-unarchiver temurin multipass"

    # Advanced tier adds these (includes virtualization and AI/ML tools)
    local advanced_casks="intellij-idea-ce jetbrains-toolbox goland webstorm datagrip zed sublime-text warp alacritty kitty lens google-cloud-sdk firefox-developer-edition arc chromium tor-browser opera wireshark ngrok lm-studio gpt4all jan msty mongodb-compass tableplus pgadmin4 microsoft-teams whatsapp telegram signal raycast alfred notion obsidian insomnia bruno vlc bitwarden keepassxc stats hiddenbar monitorcontrol appcleaner utm diffusionbee drawthings"

    case "$tier" in
        light) all_casks="$light_casks" ;;
        standard) all_casks="$light_casks $standard_casks" ;;
        advanced) all_casks="$light_casks $standard_casks $advanced_casks" ;;
    esac

    # Filter out excluded categories
    for cask in $all_casks; do
        local category=$(get_cask_category "$cask")
        if ! is_category_excluded "$category"; then
            casks="$casks $cask"
        fi
    done

    echo "$casks"
}

# Draw progress bar
# Usage: draw_progress_bar current total width label
draw_progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-40}
    local label="${4:-}"
    local elapsed="${5:-0}"

    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    # Build the progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    # Format elapsed time
    local time_str=""
    if [[ $elapsed -gt 0 ]]; then
        local mins=$((elapsed / 60))
        local secs=$((elapsed % 60))
        if [[ $mins -gt 0 ]]; then
            time_str="${mins}m ${secs}s"
        else
            time_str="${secs}s"
        fi
    fi

    # Truncate label if too long
    local max_label=20
    if [[ ${#label} -gt $max_label ]]; then
        label="${label:0:$((max_label-3))}..."
    fi

    # Print progress bar (overwrite line)
    printf "\r  ${CYAN}[${bar}]${NC} %3d%% (%d/%d) ${BLUE}%-20s${NC} ${YELLOW}%s${NC}    " \
        "$percent" "$current" "$total" "$label" "$time_str"
}

# Get app name for cask (for /Applications check)
get_app_name_for_cask() {
    local cask="$1"
    case "$cask" in
        iterm2) echo "iTerm" ;;
        visual-studio-code) echo "Visual Studio Code" ;;
        google-chrome) echo "Google Chrome" ;;
        firefox) echo "Firefox" ;;
        firefox-developer-edition) echo "Firefox Developer Edition" ;;
        docker) echo "Docker" ;;
        slack) echo "Slack" ;;
        discord) echo "Discord" ;;
        zoom) echo "zoom.us" ;;
        cursor) echo "Cursor" ;;
        pycharm-ce) echo "PyCharm CE" ;;
        intellij-idea-ce) echo "IntelliJ IDEA CE" ;;
        brave-browser) echo "Brave Browser" ;;
        arc) echo "Arc" ;;
        notion) echo "Notion" ;;
        obsidian) echo "Obsidian" ;;
        postman) echo "Postman" ;;
        insomnia) echo "Insomnia" ;;
        dbeaver-community) echo "DBeaver" ;;
        tableplus) echo "TablePlus" ;;
        rectangle) echo "Rectangle" ;;
        raycast) echo "Raycast" ;;
        alfred) echo "Alfred 5" ;;
        vlc) echo "VLC" ;;
        whatsapp) echo "WhatsApp" ;;
        telegram) echo "Telegram" ;;
        signal) echo "Signal" ;;
        microsoft-teams) echo "Microsoft Teams" ;;
        lm-studio) echo "LM Studio" ;;
        gpt4all) echo "GPT4All" ;;
        jan) echo "Jan" ;;
        wireshark) echo "Wireshark" ;;
        the-unarchiver) echo "The Unarchiver" ;;
        appcleaner) echo "AppCleaner" ;;
        bitwarden) echo "Bitwarden" ;;
        sublime-text) echo "Sublime Text" ;;
        zed) echo "Zed" ;;
        warp) echo "Warp" ;;
        alacritty) echo "Alacritty" ;;
        kitty) echo "kitty" ;;
        jetbrains-toolbox) echo "JetBrains Toolbox" ;;
        goland) echo "GoLand" ;;
        webstorm) echo "WebStorm" ;;
        datagrip) echo "DataGrip" ;;
        spotify) echo "Spotify" ;;
        keepassxc) echo "KeePassXC" ;;
        mongodb-compass) echo "MongoDB Compass" ;;
        pgadmin4) echo "pgAdmin 4" ;;
        lens) echo "Lens" ;;
        ngrok) echo "ngrok" ;;
        bruno) echo "Bruno" ;;
        stats) echo "Stats" ;;
        hiddenbar) echo "Hidden Bar" ;;
        monitorcontrol) echo "MonitorControl" ;;
        chromium) echo "Chromium" ;;
        tor-browser) echo "Tor Browser" ;;
        opera) echo "Opera" ;;
        msty) echo "Msty" ;;
        google-cloud-sdk) echo "Google Cloud SDK" ;;
        temurin) echo "Temurin" ;;
        virtualbox) echo "VirtualBox" ;;
        multipass) echo "Multipass" ;;
        utm) echo "UTM" ;;
        diffusionbee) echo "DiffusionBee" ;;
        drawthings) echo "Draw Things" ;;
        *) echo "" ;;
    esac
}

# Sync all installed packages to state file (regardless of tier)
sync_state_file() {
    local state_dir="$HOME/.mac-dev-machine"
    local state_file="$state_dir/installed.txt"
    mkdir -p "$state_dir"

    local timestamp=$(date +%Y-%m-%d_%H:%M:%S)
    local start_time=$(date +%s)

    # All known formulas across all tiers
    local all_formulas="git gh pyenv nvm neovim jq bat ripgrep fzf htop git-lfs glab lazygit git-delta tmux starship go rustup-init maven gradle kubectl helm terraform yq eza fd zoxide wget httpie tree postgresql@16 redis vagrant packer rbenv ruby-build bun deno tig git-flow k9s kubectx minikube kind terragrunt tflint ansible awscli azure-cli pulumi trivy telnet nmap mtr mitmproxy mkcert mysql sqlite ffmpeg imagemagick btop ncdu tldr thefuck shellcheck chromedriver geckodriver openssl readline sqlite3 xz zlib tcl-tk pyenv-virtualenv qemu lima colima podman ollama llama.cpp huggingface-cli qdrant milvus"

    # All known casks across all tiers
    local all_casks="iterm2 visual-studio-code google-chrome firefox virtualbox cursor pycharm-ce docker brave-browser dbeaver-community slack discord zoom rectangle postman the-unarchiver temurin multipass intellij-idea-ce jetbrains-toolbox goland webstorm datagrip zed sublime-text warp alacritty kitty lens google-cloud-sdk firefox-developer-edition arc chromium tor-browser opera wireshark ngrok lm-studio gpt4all jan msty mongodb-compass tableplus pgadmin4 microsoft-teams whatsapp telegram signal raycast alfred notion obsidian insomnia bruno vlc bitwarden keepassxc stats hiddenbar monitorcontrol appcleaner utm diffusionbee drawthings"

    # Convert to arrays and count
    local formula_array=($all_formulas)
    local cask_array=($all_casks)
    local total_formulas=${#formula_array[@]}
    local total_casks=${#cask_array[@]}
    local total=$((total_formulas + total_casks))

    local current=0
    local found_formulas=0
    local found_casks=0

    echo -e "  ${CYAN}Scanning $total_formulas formulas and $total_casks casks...${NC}"
    echo ""

    # Sync formulas with progress
    for formula in "${formula_array[@]}"; do
        ((current++))
        local elapsed=$(( $(date +%s) - start_time ))
        draw_progress_bar $current $total 40 "$formula" $elapsed

        if brew list "$formula" &>/dev/null 2>&1; then
            ((found_formulas++))
            if ! grep -q "^formula|${formula}|" "$state_file" 2>/dev/null; then
                echo "formula|${formula}|${formula}|${timestamp}" >> "$state_file"
            fi
        fi
    done

    # Sync casks with progress
    for cask in "${cask_array[@]}"; do
        ((current++))
        local elapsed=$(( $(date +%s) - start_time ))
        draw_progress_bar $current $total 40 "$cask" $elapsed

        local is_installed=false
        local display_name="$cask"
        local app_name=$(get_app_name_for_cask "$cask")

        if brew list --cask "$cask" &>/dev/null 2>&1; then
            is_installed=true
            [[ -n "$app_name" ]] && display_name="$app_name"
        elif [[ -n "$app_name" ]]; then
            # Check /Applications folder
            if [[ -d "/Applications/${app_name}.app" ]] || [[ -d "$HOME/Applications/${app_name}.app" ]]; then
                is_installed=true
                display_name="$app_name"
            fi
        fi

        if $is_installed; then
            ((found_casks++))
            if ! grep -q "^cask|${cask}|" "$state_file" 2>/dev/null; then
                echo "cask|${cask}|${display_name}|${timestamp}" >> "$state_file"
            fi
        fi
    done

    # Clear progress line and print summary
    local total_elapsed=$(( $(date +%s) - start_time ))
    echo ""
    echo ""
    echo -e "  ${GREEN}✓${NC} Scan complete in ${total_elapsed}s - Found: ${GREEN}${found_formulas}${NC} formulas, ${GREEN}${found_casks}${NC} casks"
    echo ""
}

# Pre-install scan - check what's already installed and sync state file
pre_install_scan() {
    log_section "Pre-Installation Scan"

    # First, sync ALL known packages to state file (with progress bar)
    sync_state_file

    local formulas=$(get_package_formulas "$PACKAGE_TIER")
    local casks=$(get_package_casks "$PACKAGE_TIER")
    local state_file="$HOME/.mac-dev-machine/installed.txt"

    # Counters and lists
    local installed_formulas_count=0
    local missing_formulas_count=0
    local installed_casks_count=0
    local missing_casks_count=0
    local missing_formulas_list=""
    local missing_casks_list=""
    local installed_formulas_list=""
    local installed_casks_list=""

    echo -e "  ${CYAN}Analyzing ${PACKAGE_TIER} package requirements...${NC}"
    echo ""

    # Check formulas using state file (fast lookup)
    for formula in $formulas; do
        if grep -q "^formula|${formula}|" "$state_file" 2>/dev/null; then
            ((installed_formulas_count++))
            installed_formulas_list+="$formula "
        else
            ((missing_formulas_count++))
            missing_formulas_list+="$formula "
        fi
    done

    # Check casks using state file (fast lookup)
    for cask in $casks; do
        if grep -q "^cask|${cask}|" "$state_file" 2>/dev/null; then
            ((installed_casks_count++))
            installed_casks_list+="$cask "
        else
            ((missing_casks_count++))
            missing_casks_list+="$cask "
        fi
    done

    # Get total count from state file
    local state_total=$(wc -l < "$state_file" 2>/dev/null | tr -d ' ' || echo "0")

    # Display results
    local total_installed=$((installed_formulas_count + installed_casks_count))
    local total_missing=$((missing_formulas_count + missing_casks_count))
    local total=$((total_installed + total_missing))

    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  SCAN RESULTS - Package: $PACKAGE_TIER${NC}"
    if [[ -n "$EXCLUDED_CATEGORIES" ]]; then
        echo -e "${YELLOW}  Excluded: $EXCLUDED_CATEGORIES${NC}"
    fi
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}Already installed:${NC} $total_installed packages (in this tier)"
    echo -e "  ${YELLOW}Will be installed:${NC} $total_missing packages"
    echo -e "  ${CYAN}Total in package:${NC}  $total packages"
    echo ""
    echo -e "  ${BLUE}State file:${NC} $state_file ($state_total total tracked)"
    echo ""

    # Show previous exclusions if running with --only or if config exists
    if [[ -n "$ONLY_CATEGORIES" ]]; then
        echo -e "  ${GREEN}Adding categories:${NC} $ONLY_CATEGORIES"
        echo ""
    elif [[ -f "$CONFIG_FILE" ]]; then
        local prev_excluded=$(get_previous_exclusions)
        if [[ -n "$prev_excluded" ]]; then
            echo -e "  ${YELLOW}Previously excluded:${NC} $prev_excluded"
            echo -e "  ${CYAN}To add them:${NC} ./install.sh --package $PACKAGE_TIER --only $prev_excluded"
            echo ""
        fi
    fi

    if [[ $installed_formulas_count -gt 0 ]]; then
        echo -e "${GREEN}Installed formulas ($installed_formulas_count):${NC}"
        echo "$installed_formulas_list" | tr ' ' '\n' | grep -v '^$' | sort | pr -4 -t -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ $installed_casks_count -gt 0 ]]; then
        echo -e "${GREEN}Installed casks ($installed_casks_count):${NC}"
        echo "$installed_casks_list" | tr ' ' '\n' | grep -v '^$' | sort | pr -4 -t -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ $missing_formulas_count -gt 0 ]]; then
        echo -e "${YELLOW}Formulas to install ($missing_formulas_count):${NC}"
        echo "$missing_formulas_list" | tr ' ' '\n' | grep -v '^$' | sort | pr -4 -t -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ $missing_casks_count -gt 0 ]]; then
        echo -e "${YELLOW}Casks to install ($missing_casks_count):${NC}"
        echo "$missing_casks_list" | tr ' ' '\n' | grep -v '^$' | sort | pr -4 -t -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ $total_missing -eq 0 ]]; then
        echo -e "${GREEN}Everything is already installed!${NC}"
        echo ""
        if [[ "$AUTO_YES" != true ]]; then
            read -p "Run anyway to verify and update configurations? [y/N]: " response
            case "$response" in
                [yY][eE][sS]|[yY]) return 0 ;;
                *) log_info "Nothing to install."; exit 0 ;;
            esac
        fi
    fi

    # Store for later use
    export MISSING_FORMULAS="$missing_formulas_list"
    export MISSING_CASKS="$missing_casks_list"

    log_success "State file synced with $total_installed installed packages"
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

    # Refresh sudo before each module (keeps sudo alive during long installs)
    if [[ -n "$SUDO_PASSWORD" ]]; then
        echo "$SUDO_PASSWORD" | sudo -S -v 2>/dev/null
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
    # Show help if no arguments
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    # Handle --show-packages early
    parse_args "$@"

    if [[ "$SHOW_PACKAGES" == true ]]; then
        show_package_contents
        exit 0
    fi

    # Handle --add mode (install specific tools)
    if [[ -n "$ADD_TOOLS" ]]; then
        print_banner
        install_specific_tools "$ADD_TOOLS"
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

    # Initialize sudo for full automation
    if [[ -n "$SUDO_PASSWORD" ]]; then
        init_sudo
    fi

    # Select package
    select_package

    # Pre-install scan - show what will be installed
    pre_install_scan

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
    export SUDO_PASSWORD
    export SUDO_ASKPASS
    export HOMEBREW_SUDO_ASKPASS
    export EXCLUDED_CATEGORIES

    # Run installation modules based on package tier
    log_section "Starting Installation ($PACKAGE_TIER)"

    # Show excluded categories if any
    if [[ -n "$EXCLUDED_CATEGORIES" ]]; then
        log_warning "Excluding categories: $EXCLUDED_CATEGORIES"
        echo ""
    fi

    # System essentials (always required)
    run_module "01-system-essentials.sh"

    # Helper to conditionally run module based on category exclusion
    run_module_if_not_excluded() {
        local module="$1"
        shift
        local categories="$@"

        for cat in $categories; do
            if is_category_excluded "$cat"; then
                log_info "Skipping $module (category '$cat' excluded)"
                return 0
            fi
        done
        run_module "$module"
    }

    # Package-based installation with category filtering
    case $PACKAGE_TIER in
        light)
            run_module_if_not_excluded "02-dev-tools.sh" editors git terminal
            run_module_if_not_excluded "03-languages.sh" languages
            run_module_if_not_excluded "05-cli-tools.sh" cli
            run_module_if_not_excluded "09-browsers.sh" browsers
            ;;
        standard)
            run_module_if_not_excluded "02-dev-tools.sh" editors git terminal
            run_module_if_not_excluded "03-languages.sh" languages
            run_module_if_not_excluded "04-devops-tools.sh" devops virtualization
            run_module_if_not_excluded "05-cli-tools.sh" cli
            run_module_if_not_excluded "09-browsers.sh" browsers
            run_module_if_not_excluded "10-databases.sh" databases
            run_module_if_not_excluded "07-communication.sh" communication
            run_module_if_not_excluded "11-optional-apps.sh" apps
            ;;
        advanced)
            run_module_if_not_excluded "02-dev-tools.sh" editors git terminal
            run_module_if_not_excluded "03-languages.sh" languages
            run_module_if_not_excluded "04-devops-tools.sh" devops virtualization
            run_module_if_not_excluded "05-cli-tools.sh" cli
            run_module_if_not_excluded "06-network-tools.sh" network
            run_module_if_not_excluded "07-communication.sh" communication
            run_module_if_not_excluded "08-ai-tools.sh" ai
            run_module_if_not_excluded "09-browsers.sh" browsers
            run_module_if_not_excluded "10-databases.sh" databases
            run_module_if_not_excluded "11-optional-apps.sh" apps
            ;;
    esac

    # Configure dotfiles
    if [[ "$SKIP_DOTFILES" != true ]]; then
        log_section "Configuring Dotfiles"
        configure_dotfiles
    fi

    # Save installation state and config
    log_section "Saving Installation State"
    save_state_summary
    update_state_timestamp
    save_install_config

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
