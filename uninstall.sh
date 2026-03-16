#!/bin/bash
#
# Mac Dev Machine - Uninstall Script
# Removes only tools that were installed by this setup
#
# Copyright (c) 2024-2026 Devopz.ai
# Author: Rashed Ahmed <rashed.ahmed@devopz.ai>
# License: MIT
#
# Usage:
#   ./uninstall.sh                     # Show help
#   ./uninstall.sh --tools <list>      # Uninstall specific tools
#   ./uninstall.sh --category <cat>    # Uninstall by category
#   ./uninstall.sh --all               # Uninstall everything
#

set +e  # Continue on errors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

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
}

STATE_DIR="$HOME/.mac-dev-machine"
STATE_FILE="$STATE_DIR/installed.txt"
CUSTOM_FILE="$STATE_DIR/custom-tools.txt"
CONFIG_FILE="$STATE_DIR/config.txt"

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

# Get tool's install type from state files
get_tool_install_type() {
    local tool="$1"

    # Check state file
    if [[ -f "$STATE_FILE" ]]; then
        local type=$(grep "|${tool}|" "$STATE_FILE" 2>/dev/null | head -1 | cut -d'|' -f1)
        if [[ -n "$type" ]]; then
            echo "$type"
            return 0
        fi
    fi

    # Check custom tools file
    if [[ -f "$CUSTOM_FILE" ]]; then
        local method=$(grep "^${tool}|" "$CUSTOM_FILE" 2>/dev/null | cut -d'|' -f2)
        if [[ -n "$method" ]]; then
            echo "$method"
            return 0
        fi
    fi

    # Auto-detect
    if brew list "$tool" &>/dev/null 2>&1; then
        echo "formula"
    elif brew list --cask "$tool" &>/dev/null 2>&1; then
        echo "cask"
    elif pip3 show "$tool" &>/dev/null 2>&1; then
        echo "pip"
    elif npm list -g "$tool" &>/dev/null 2>&1; then
        echo "npm"
    else
        echo "unknown"
    fi
}

# Remove tool from state file
remove_tool_from_state() {
    local tool="$1"

    if [[ -f "$STATE_FILE" ]]; then
        local temp_file=$(mktemp)
        grep -v "|${tool}|" "$STATE_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$STATE_FILE"
    fi

    if [[ -f "$CUSTOM_FILE" ]]; then
        local temp_file=$(mktemp)
        grep -v "^${tool}|" "$CUSTOM_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$CUSTOM_FILE"
    fi
}

# Uninstall a single tool based on its type
uninstall_tool() {
    local tool="$1"
    local install_type=$(get_tool_install_type "$tool")
    local method_type=$(echo "$install_type" | cut -d: -f1)
    local method_value=$(echo "$install_type" | cut -d: -f2-)

    echo -e "${CYAN}Uninstalling:${NC} $tool (${method_type})"

    local success=false

    case "$method_type" in
        formula)
            if brew list "$tool" &>/dev/null 2>&1; then
                brew uninstall "$tool" && success=true
            else
                log_info "$tool not installed (formula)"
                success=true
            fi
            ;;
        cask)
            if brew list --cask "$tool" &>/dev/null 2>&1; then
                brew uninstall --cask "$tool" && success=true
            else
                log_info "$tool not installed (cask)"
                success=true
            fi
            ;;
        pip)
            local pkg="${method_value:-$tool}"
            if pip3 show "$pkg" &>/dev/null 2>&1; then
                pip3 uninstall -y "$pkg" && success=true
            else
                log_info "$tool not installed (pip)"
                success=true
            fi
            ;;
        npm)
            local pkg="${method_value:-$tool}"
            if npm list -g "$pkg" &>/dev/null 2>&1; then
                npm uninstall -g "$pkg" && success=true
            else
                log_info "$tool not installed (npm)"
                success=true
            fi
            ;;
        tap)
            # Installed via tap
            if brew list "$tool" &>/dev/null 2>&1; then
                brew uninstall "$tool" && success=true
                # Optionally untap
                if [[ -n "$method_value" ]]; then
                    log_info "Tap $method_value kept (may be used by other packages)"
                fi
            else
                success=true
            fi
            ;;
        url)
            # Installed via URL - check common locations
            log_warning "$tool was installed via URL download"

            # Check /Applications
            local app_name=$(echo "$tool" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
            if [[ -d "/Applications/${app_name}.app" ]]; then
                log_step "Removing /Applications/${app_name}.app..."
                rm -rf "/Applications/${app_name}.app" && success=true
            elif [[ -d "$HOME/Applications/${app_name}.app" ]]; then
                log_step "Removing ~/Applications/${app_name}.app..."
                rm -rf "$HOME/Applications/${app_name}.app" && success=true
            fi

            # Check /usr/local/bin
            if [[ -f "/usr/local/bin/$tool" ]]; then
                log_step "Removing /usr/local/bin/$tool..."
                sudo rm -f "/usr/local/bin/$tool" && success=true
            fi

            if ! $success; then
                log_warning "Could not find $tool to remove. Check manually."
                success=true  # Mark as done to continue
            fi
            ;;
        custom)
            log_warning "$tool was installed via custom command:"
            echo "  $method_value"
            echo ""
            read -p "Enter uninstall command (or press Enter to skip): " uninstall_cmd
            if [[ -n "$uninstall_cmd" ]]; then
                eval "$uninstall_cmd" && success=true
            else
                log_info "Skipped"
                success=true
            fi
            ;;
        unknown)
            # Try common methods
            if brew list "$tool" &>/dev/null 2>&1; then
                brew uninstall "$tool" && success=true
            elif brew list --cask "$tool" &>/dev/null 2>&1; then
                brew uninstall --cask "$tool" && success=true
            elif pip3 show "$tool" &>/dev/null 2>&1; then
                pip3 uninstall -y "$tool" && success=true
            elif npm list -g "$tool" &>/dev/null 2>&1; then
                npm uninstall -g "$tool" && success=true
            else
                log_warning "$tool not found"
                success=true
            fi
            ;;
    esac

    if $success; then
        log_success "$tool removed"
        remove_tool_from_state "$tool"
    else
        log_error "Failed to remove $tool"
    fi
}

# Uninstall specific tools
uninstall_tools() {
    local tools="$1"
    log_section "Uninstalling Specific Tools"

    local tool_list=$(echo "$tools" | tr ',' ' ')
    local total=$(echo "$tool_list" | wc -w | tr -d ' ')
    local current=0
    local removed=0
    local failed=0

    for tool in $tool_list; do
        ((current++))
        echo ""
        echo -e "${BLUE}[$current/$total]${NC} $tool"
        uninstall_tool "$tool"
    done

    echo ""
    log_success "Uninstall complete"
}

# Uninstall tools by category
uninstall_category() {
    local category="$1"
    log_section "Uninstalling Category: $category"

    # Get tools for category
    local tools=""

    case "$category" in
        terminal)
            tools="iterm2 tmux starship warp alacritty kitty"
            ;;
        editors)
            tools="visual-studio-code cursor neovim pycharm-ce intellij-idea-ce zed sublime-text jetbrains-toolbox goland webstorm datagrip"
            ;;
        languages)
            tools="pyenv nvm go rustup-init rbenv ruby-build bun deno temurin maven gradle"
            ;;
        git)
            tools="git gh git-lfs glab lazygit git-delta tig git-flow"
            ;;
        devops)
            tools="docker kubectl helm terraform k9s kubectx minikube kind terragrunt tflint ansible awscli azure-cli pulumi packer lens google-cloud-sdk"
            ;;
        virtualization)
            tools="virtualbox vagrant multipass utm qemu lima colima podman"
            ;;
        cli)
            tools="jq bat ripgrep fzf htop yq eza fd zoxide wget httpie tree btop ncdu tldr thefuck shellcheck ffmpeg imagemagick"
            ;;
        network)
            tools="wireshark nmap mtr mitmproxy mkcert ngrok telnet"
            ;;
        ai)
            tools="ollama lm-studio gpt4all jan llama.cpp huggingface-cli qdrant milvus diffusionbee drawthings"
            ;;
        databases)
            tools="postgresql@16 redis mysql sqlite dbeaver-community tableplus mongodb-compass pgadmin4"
            ;;
        browsers)
            tools="google-chrome firefox brave-browser arc firefox-developer-edition chromium tor-browser opera"
            ;;
        communication)
            tools="slack discord zoom microsoft-teams whatsapp telegram signal"
            ;;
        apps)
            tools="rectangle postman the-unarchiver raycast alfred notion obsidian insomnia bruno vlc bitwarden keepassxc stats hiddenbar appcleaner"
            ;;
        *)
            log_error "Unknown category: $category"
            log_info "Valid categories: terminal, editors, languages, git, devops, virtualization, cli, network, ai, databases, browsers, communication, apps"
            return 1
            ;;
    esac

    # Filter to only installed tools
    local installed_tools=""
    for tool in $tools; do
        local install_type=$(get_tool_install_type "$tool")
        if [[ "$install_type" != "unknown" ]] || brew list "$tool" &>/dev/null 2>&1 || brew list --cask "$tool" &>/dev/null 2>&1; then
            installed_tools="$installed_tools $tool"
        fi
    done

    if [[ -z "$installed_tools" ]]; then
        log_info "No installed tools found in category: $category"
        return 0
    fi

    echo "Tools to uninstall from $category:"
    echo "$installed_tools" | tr ' ' '\n' | grep -v '^$' | sed 's/^/  - /'
    echo ""

    read -p "Proceed with uninstall? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Cancelled"
        return 0
    fi

    uninstall_tools "$(echo $installed_tools | tr ' ' ',')"
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

    # Show custom tools
    if [[ -f "$CUSTOM_FILE" ]] && [[ -s "$CUSTOM_FILE" ]]; then
        local custom_count=$(grep -v "^#" "$CUSTOM_FILE" 2>/dev/null | grep -v "^$" | wc -l | tr -d ' ')
        if [[ "$custom_count" -gt 0 ]]; then
            echo -e "${CYAN}Custom tools:${NC} $custom_count"
            grep -v "^#" "$CUSTOM_FILE" 2>/dev/null | grep -v "^$" | while IFS='|' read -r tool method date; do
                echo "  - $tool ($method)"
            done
            echo ""
        fi
    fi
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

    # Show custom tools
    if [[ -f "$CUSTOM_FILE" ]] && [[ -s "$CUSTOM_FILE" ]]; then
        echo -e "${CYAN}=== Custom Tools ===${NC}"
        grep -v "^#" "$CUSTOM_FILE" 2>/dev/null | grep -v "^$" | while IFS='|' read -r tool method date; do
            echo "  - $tool (via $method)"
        done
        echo ""
    fi
}

# Uninstall all formulas
uninstall_formulas() {
    log_step "Uninstalling Homebrew formulas..."

    grep "^formula|" "$STATE_FILE" 2>/dev/null | while IFS='|' read -r type pkg name date; do
        if brew list "$pkg" &>/dev/null; then
            log_step "Removing $name..."
            if brew uninstall "$pkg" 2>/dev/null; then
                log_success "Removed $name"
                remove_tool_from_state "$pkg"
            else
                log_warning "Could not remove $name"
            fi
        else
            log_info "$name already removed"
            remove_tool_from_state "$pkg"
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
                remove_tool_from_state "$pkg"
            else
                log_warning "Could not remove $name"
            fi
        else
            log_info "$name already removed"
            remove_tool_from_state "$pkg"
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
            remove_tool_from_state "$pkg"
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
            remove_tool_from_state "$pkg"
        else
            log_warning "Could not remove $name"
        fi
    done
}

# Uninstall custom tools
uninstall_custom() {
    log_step "Uninstalling custom tools..."

    if [[ ! -f "$CUSTOM_FILE" ]] || [[ ! -s "$CUSTOM_FILE" ]]; then
        log_info "No custom tools to uninstall"
        return
    fi

    grep -v "^#" "$CUSTOM_FILE" 2>/dev/null | grep -v "^$" | while IFS='|' read -r tool method date; do
        echo ""
        uninstall_tool "$tool"
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
        /^# Mac Dev Machine Setup$/,/^$/ { next }
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
    uninstall_custom
    uninstall_casks
    uninstall_formulas
    uninstall_version_managers
    cleanup_shell_config

    # Cleanup Homebrew
    log_step "Cleaning up Homebrew..."
    brew cleanup --prune=all 2>/dev/null || true
    brew autoremove 2>/dev/null || true

    # Remove state files
    rm -f "$STATE_FILE"
    rm -f "$CUSTOM_FILE"
    rm -f "$CONFIG_FILE"

    # Remove auto-update cron if exists
    (crontab -l 2>/dev/null | grep -v "mac-dev-machine") | crontab - 2>/dev/null || true

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
        custom)
            uninstall_custom
            ;;
        *)
            log_error "Unknown type: $type"
            log_info "Valid types: formula, cask, npm, pip, custom"
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
    echo "  3) Uninstall specific tools"
    echo "  4) Uninstall by category"
    echo "  5) Uninstall Homebrew Formulas only"
    echo "  6) Uninstall Homebrew Casks only"
    echo "  7) Uninstall NPM packages only"
    echo "  8) Uninstall Pip packages only"
    echo "  9) Uninstall custom tools only"
    echo "  V) Uninstall version managers (pyenv, nvm, rbenv, rust)"
    echo "  C) Clean shell configuration only"
    echo ""
    echo "  A) UNINSTALL EVERYTHING"
    echo "  Q) Quit"
    echo ""
}

# Force rescan with time estimate and confirmation
force_scan() {
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
        rm -f "$STATE_FILE"
        "${SCRIPT_DIR}/scan-installed.sh" -r
    else
        log_info "Scan cancelled"
    fi
}

# Usage help
usage() {
    echo ""
    echo -e "${BLUE}Mac Dev Machine - Uninstall Script${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
    echo "Remove packages installed by Mac Dev Machine setup."
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  ./uninstall.sh [OPTIONS]"
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo "  --list, -l              Show installed packages summary"
    echo "  --detailed, -d          Show detailed package list"
    echo "  --scan, -s              Force rescan of installed packages"
    echo "  --interactive, -i       Interactive menu mode"
    echo "  --all, -a               Uninstall everything (requires confirmation)"
    echo "  --type, -t TYPE         Uninstall by type: formula, cask, npm, pip, custom"
    echo "  --tools TOOLS           Uninstall specific tools (comma-separated)"
    echo "  --category, -c CAT      Uninstall by category"
    echo "  --version, -v           Show version information"
    echo "  --help, -h              Show this help"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  ./uninstall.sh --list                    # Show what's tracked"
    echo "  ./uninstall.sh --tools ollama,htop       # Remove specific tools"
    echo "  ./uninstall.sh --category ai             # Remove all AI tools"
    echo "  ./uninstall.sh --category communication  # Remove chat apps"
    echo "  ./uninstall.sh --type cask               # Remove all casks"
    echo "  ./uninstall.sh --all                     # Remove everything"
    echo ""
    echo -e "${CYAN}Categories:${NC}"
    echo "  terminal, editors, languages, git, devops, virtualization,"
    echo "  cli, network, ai, databases, browsers, communication, apps"
    echo ""
    echo -e "${CYAN}State Files:${NC}"
    echo "  ~/.mac-dev-machine/installed.txt"
    echo "  ~/.mac-dev-machine/custom-tools.txt"
    echo ""
}

# Show quick summary of installed packages
show_quick_summary() {
    if [[ -f "$STATE_FILE" ]] && [[ -s "$STATE_FILE" ]]; then
        local formulas=$(grep -c "^formula|" "$STATE_FILE" 2>/dev/null || echo 0)
        local casks=$(grep -c "^cask|" "$STATE_FILE" 2>/dev/null || echo 0)
        local npms=$(grep -c "^npm|" "$STATE_FILE" 2>/dev/null || echo 0)
        local pips=$(grep -c "^pip|" "$STATE_FILE" 2>/dev/null || echo 0)
        local total=$((formulas + casks + npms + pips))

        echo -e "${GREEN}Installed Packages:${NC}"
        echo "  Formulas: $formulas | Casks: $casks | NPM: $npms | Pip: $pips | Total: $total"
        echo ""
        echo "  Run './uninstall.sh --list' for summary or '--detailed' for full list"
        echo ""
    else
        echo -e "${YELLOW}No installation record found.${NC}"
        echo "  Run './uninstall.sh --scan' or './install.sh --scan' to scan installed packages"
        echo ""
    fi
}

# Main
main() {
    print_header

    # Show help if no arguments
    if [[ $# -eq 0 ]]; then
        show_quick_summary
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
        --tools)
            uninstall_tools "${2:-}"
            exit 0
            ;;
        --category|-c)
            uninstall_category "${2:-}"
            exit 0
            ;;
        --interactive|-i)
            # Continue to interactive mode below
            ;;
        --version|-v)
            show_version
            exit 0
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
        read -p "Enter choice [1-9, V, C, A, Q]: " choice
        echo ""

        case $choice in
            1) show_installed ;;
            2) show_detailed_list ;;
            3)
                read -p "Enter tool names (comma-separated): " tools
                [[ -n "$tools" ]] && uninstall_tools "$tools"
                ;;
            4)
                echo "Categories: terminal, editors, languages, git, devops, virtualization, cli, network, ai, databases, browsers, communication, apps"
                read -p "Enter category: " cat
                [[ -n "$cat" ]] && uninstall_category "$cat"
                ;;
            5) uninstall_formulas ;;
            6) uninstall_casks ;;
            7) uninstall_npm ;;
            8) uninstall_pip ;;
            9) uninstall_custom ;;
            [Vv]) uninstall_version_managers ;;
            [Cc]) cleanup_shell_config ;;
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
