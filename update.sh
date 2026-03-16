#!/bin/bash
#
# Mac Dev Machine - Update Script
# Updates installed tools to their latest versions
#
# Copyright (c) 2024-2026 Devopz.ai
# Author: Rashed Ahmed <rashed.ahmed@devopz.ai>
# License: MIT
#
# Usage:
#   ./update.sh                      # Show help
#   ./update.sh --all                # Update everything
#   ./update.sh --tools <list>       # Update specific tools
#   ./update.sh --category <cat>     # Update specific category
#   ./update.sh --check              # Check for updates (dry run)
#   ./update.sh --auto-enable        # Enable automatic updates (cron)
#   ./update.sh --auto-add <tools>   # Add tools to auto-update list
#

set -e

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

# Config files
STATE_DIR="$HOME/.mac-dev-machine"
STATE_FILE="$STATE_DIR/installed.txt"
CUSTOM_FILE="$STATE_DIR/custom-tools.txt"
AUTO_UPDATE_FILE="$STATE_DIR/auto-update.txt"
AUTO_UPDATE_LOG="$STATE_DIR/auto-update.log"
CRON_SCRIPT="$STATE_DIR/cron-update.sh"

# Parse arguments
ACTION="help"
TOOLS_LIST=""
CATEGORY=""
AUTO_TOOLS=""
CRON_SCHEDULE="0 9 * * 6"  # Default: Saturday 9am

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --brew)
                ACTION="brew"
                shift
                ;;
            --languages)
                ACTION="languages"
                shift
                ;;
            --npm)
                ACTION="npm"
                shift
                ;;
            --pip)
                ACTION="pip"
                shift
                ;;
            --check)
                ACTION="check"
                shift
                ;;
            --all|-a)
                ACTION="all"
                shift
                ;;
            --tools|-t)
                ACTION="tools"
                TOOLS_LIST="$2"
                shift 2
                ;;
            --category|-c)
                ACTION="category"
                CATEGORY="$2"
                shift 2
                ;;
            --auto-enable)
                ACTION="auto-enable"
                shift
                ;;
            --auto-disable)
                ACTION="auto-disable"
                shift
                ;;
            --auto-add)
                ACTION="auto-add"
                AUTO_TOOLS="$2"
                shift 2
                ;;
            --auto-remove)
                ACTION="auto-remove"
                AUTO_TOOLS="$2"
                shift 2
                ;;
            --auto-add-category)
                ACTION="auto-add-category"
                CATEGORY="$2"
                shift 2
                ;;
            --auto-remove-category)
                ACTION="auto-remove-category"
                CATEGORY="$2"
                shift 2
                ;;
            --auto-list)
                ACTION="auto-list"
                shift
                ;;
            --auto-scan)
                ACTION="auto-scan"
                shift
                ;;
            --auto-run)
                ACTION="auto-run"
                shift
                ;;
            --schedule)
                CRON_SCHEDULE="$2"
                shift 2
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

show_help() {
    cat << 'EOF'
Mac Dev Machine - Update Script

Usage: ./update.sh [OPTIONS]

Update Options:
    --all, -a           Update everything (Homebrew, languages, npm, pip)
    --brew              Update Homebrew packages only
    --languages         Update language runtimes (Python, Node, etc.)
    --npm               Update global NPM packages only
    --pip               Update pip packages only
    --check             Check for available updates (dry run)

Specific Updates:
    --tools, -t <list>      Update specific tools (comma-separated)
    --category, -c <cat>    Update tools in specific category

Auto-Update (Cron):
    --auto-enable               Enable automatic updates via cron
    --auto-disable              Disable automatic updates
    --auto-add <tools>          Add tools to auto-update list
    --auto-remove <tools>       Remove tools from auto-update list
    --auto-add-category <cat>   Add entire category to auto-update
    --auto-remove-category <cat> Remove entire category from auto-update
    --auto-list                 Show auto-update configuration
    --auto-scan                 Scan for available tools to add
    --schedule "<cron>"         Set cron schedule (default: "0 9 * * 6" = Sat 9am)
    --version, -v               Show version information

Examples:
    ./update.sh --all                        # Update everything
    ./update.sh --tools ollama,htop          # Update specific tools
    ./update.sh --category ai                # Update AI tools
    ./update.sh --auto-enable                # Enable weekly auto-updates
    ./update.sh --auto-add ollama,docker     # Add tools to auto-update
    ./update.sh --auto-add-category ai       # Add all AI tools to auto-update
    ./update.sh --auto-add-category devops   # Add all DevOps tools
    ./update.sh --auto-remove-category ai    # Remove AI from auto-update
    ./update.sh --schedule "0 3 * * 0"       # Change to Sunday 3am

Categories: system, terminal, editors, languages, git, devops, virtualization,
            cli, network, ai, databases, browsers, communication, apps

EOF
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

# Update a single tool based on its type
update_tool() {
    local tool="$1"
    local install_type=$(get_tool_install_type "$tool")
    local method_type=$(echo "$install_type" | cut -d: -f1)
    local method_value=$(echo "$install_type" | cut -d: -f2-)

    echo -e "${CYAN}Updating:${NC} $tool (${method_type})"

    case "$method_type" in
        formula)
            brew upgrade "$tool" 2>/dev/null || log_info "$tool is up to date"
            ;;
        cask)
            brew upgrade --cask "$tool" 2>/dev/null || log_info "$tool is up to date"
            ;;
        pip)
            pip3 install --upgrade "${method_value:-$tool}" 2>/dev/null || log_info "$tool is up to date"
            ;;
        npm)
            npm update -g "${method_value:-$tool}" 2>/dev/null || log_info "$tool is up to date"
            ;;
        tap)
            brew upgrade "$tool" 2>/dev/null || log_info "$tool is up to date"
            ;;
        url)
            log_warning "$tool was installed via URL. Re-run install with new URL to update:"
            echo "  ./install.sh --add $tool"
            ;;
        custom)
            log_warning "$tool was installed via custom command:"
            echo "  $method_value"
            log_info "Re-run the command manually to update"
            ;;
        unknown)
            # Try brew first
            if brew upgrade "$tool" 2>/dev/null; then
                log_success "$tool updated (formula)"
            elif brew upgrade --cask "$tool" 2>/dev/null; then
                log_success "$tool updated (cask)"
            else
                log_warning "Don't know how to update $tool"
            fi
            ;;
    esac
}

# Update specific tools
update_tools() {
    local tools="$1"
    log_section "Updating Specific Tools"

    local tool_list=$(echo "$tools" | tr ',' ' ')
    local total=$(echo "$tool_list" | wc -w | tr -d ' ')
    local current=0

    for tool in $tool_list; do
        ((current++))
        echo ""
        echo -e "${BLUE}[$current/$total]${NC} $tool"
        update_tool "$tool"
    done

    echo ""
    log_success "Tool updates complete"
}

# Update tools by category
update_category() {
    local category="$1"
    log_section "Updating Category: $category"

    # Get tools for category from install.sh mappings
    local tools=""

    case "$category" in
        terminal)
            tools="iterm2 tmux starship warp alacritty kitty"
            ;;
        editors)
            tools="visual-studio-code cursor neovim pycharm-ce intellij-idea-ce zed sublime-text"
            ;;
        languages)
            tools="pyenv nvm go rustup-init rbenv ruby-build bun deno temurin"
            ;;
        git)
            tools="git gh git-lfs glab lazygit git-delta tig git-flow"
            ;;
        devops)
            tools="docker kubectl helm terraform k9s kubectx minikube kind terragrunt tflint ansible awscli azure-cli pulumi packer"
            ;;
        virtualization)
            tools="virtualbox vagrant multipass utm qemu lima colima podman"
            ;;
        cli)
            tools="jq bat ripgrep fzf htop yq eza fd zoxide wget httpie tree btop ncdu tldr"
            ;;
        network)
            tools="wireshark nmap mtr mitmproxy mkcert ngrok"
            ;;
        ai)
            tools="ollama lm-studio gpt4all jan llama.cpp huggingface-cli"
            ;;
        databases)
            tools="postgresql@16 redis mysql sqlite dbeaver-community tableplus mongodb-compass"
            ;;
        browsers)
            tools="google-chrome firefox brave-browser arc firefox-developer-edition"
            ;;
        communication)
            tools="slack discord zoom microsoft-teams whatsapp telegram signal"
            ;;
        apps)
            tools="rectangle postman the-unarchiver raycast alfred notion obsidian insomnia bruno vlc bitwarden"
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
        if brew list "$tool" &>/dev/null 2>&1 || brew list --cask "$tool" &>/dev/null 2>&1 || command -v "$tool" &>/dev/null; then
            installed_tools="$installed_tools $tool"
        fi
    done

    if [[ -z "$installed_tools" ]]; then
        log_info "No installed tools found in category: $category"
        return 0
    fi

    update_tools "$(echo $installed_tools | tr ' ' ',')"
}

# ============================================================================
# Auto-Update (Cron) Functions
# ============================================================================

# Create the cron update script
create_cron_script() {
    mkdir -p "$STATE_DIR"

    cat > "$CRON_SCRIPT" << 'CRONSCRIPT'
#!/bin/bash
# Auto-update script for Mac Dev Machine
# This script is run by cron

LOG_FILE="$HOME/.mac-dev-machine/auto-update.log"
AUTO_UPDATE_FILE="$HOME/.mac-dev-machine/auto-update.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"

# If SCRIPT_DIR detection failed, try common locations
if [[ ! -f "$SCRIPT_DIR/update.sh" ]]; then
    for dir in "$HOME/Mac-dev-machine" "$HOME/Projects/Mac-dev-machine" "/opt/Mac-dev-machine"; do
        if [[ -f "$dir/update.sh" ]]; then
            SCRIPT_DIR="$dir"
            break
        fi
    done
fi

echo "========================================" >> "$LOG_FILE"
echo "Auto-update started: $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Update Homebrew
echo "Updating Homebrew..." >> "$LOG_FILE"
brew update >> "$LOG_FILE" 2>&1

# Read auto-update list and update each tool
if [[ -f "$AUTO_UPDATE_FILE" ]]; then
    while IFS= read -r tool || [[ -n "$tool" ]]; do
        [[ -z "$tool" ]] && continue
        [[ "$tool" =~ ^# ]] && continue

        echo "Updating: $tool" >> "$LOG_FILE"

        # Try formula first, then cask
        if brew list "$tool" &>/dev/null 2>&1; then
            brew upgrade "$tool" >> "$LOG_FILE" 2>&1 || true
        elif brew list --cask "$tool" &>/dev/null 2>&1; then
            brew upgrade --cask "$tool" >> "$LOG_FILE" 2>&1 || true
        fi
    done < "$AUTO_UPDATE_FILE"
else
    # No specific list, update all brew packages
    echo "Updating all Homebrew packages..." >> "$LOG_FILE"
    brew upgrade >> "$LOG_FILE" 2>&1 || true
    brew upgrade --cask >> "$LOG_FILE" 2>&1 || true
fi

# Cleanup
brew cleanup >> "$LOG_FILE" 2>&1 || true

echo "" >> "$LOG_FILE"
echo "Auto-update completed: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
CRONSCRIPT

    chmod +x "$CRON_SCRIPT"
    log_success "Created cron script: $CRON_SCRIPT"
}

# Enable auto-updates via cron
enable_auto_update() {
    log_section "Enabling Auto-Updates"

    # Create the cron script
    create_cron_script

    # Create auto-update list if doesn't exist
    if [[ ! -f "$AUTO_UPDATE_FILE" ]]; then
        cat > "$AUTO_UPDATE_FILE" << 'EOF'
# Mac Dev Machine - Auto-Update List
# Add tool names (one per line) to auto-update
# Lines starting with # are comments
# Leave empty to update ALL Homebrew packages
#
# Example:
# ollama
# docker
# visual-studio-code
EOF
        log_info "Created auto-update list: $AUTO_UPDATE_FILE"
    fi

    # Add to cron
    local cron_entry="$CRON_SCHEDULE $CRON_SCRIPT"

    # Remove existing entry if any
    (crontab -l 2>/dev/null | grep -v "mac-dev-machine/cron-update.sh") | crontab - 2>/dev/null || true

    # Add new entry
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -

    echo ""
    log_success "Auto-updates enabled!"
    echo ""
    echo -e "  ${CYAN}Schedule:${NC} $CRON_SCHEDULE"
    echo -e "  ${CYAN}Script:${NC}   $CRON_SCRIPT"
    echo -e "  ${CYAN}Log:${NC}      $AUTO_UPDATE_LOG"
    echo -e "  ${CYAN}Tools:${NC}    $AUTO_UPDATE_FILE"
    echo ""
    echo "Cron schedule format: minute hour day month weekday"
    echo "  Default (0 9 * * 6) = Every Saturday at 9:00 AM"
    echo ""
    echo "To change schedule:"
    echo "  ./update.sh --auto-enable --schedule \"0 3 * * 0\"  # Sunday 3am"
    echo ""
    echo "To add tools to auto-update:"
    echo "  ./update.sh --auto-add ollama,docker"
    echo ""
}

# Disable auto-updates
disable_auto_update() {
    log_section "Disabling Auto-Updates"

    # Remove from cron
    (crontab -l 2>/dev/null | grep -v "mac-dev-machine/cron-update.sh") | crontab - 2>/dev/null || true

    log_success "Auto-updates disabled"
    log_info "Config files preserved. Re-enable with: ./update.sh --auto-enable"
}

# Get tools for a category
get_category_tools() {
    local category="$1"

    case "$category" in
        system)
            echo "brew"
            ;;
        terminal)
            echo "iterm2 tmux starship warp alacritty kitty"
            ;;
        editors)
            echo "visual-studio-code cursor neovim pycharm-ce intellij-idea-ce zed sublime-text"
            ;;
        languages)
            echo "pyenv nvm go rustup-init rbenv ruby-build bun deno temurin"
            ;;
        git)
            echo "git gh git-lfs glab lazygit git-delta tig git-flow"
            ;;
        devops)
            echo "docker kubectl helm terraform k9s kubectx minikube kind terragrunt tflint ansible awscli azure-cli pulumi packer"
            ;;
        virtualization)
            echo "virtualbox vagrant multipass utm qemu lima colima podman"
            ;;
        cli)
            echo "jq bat ripgrep fzf htop yq eza fd zoxide wget httpie tree btop ncdu tldr"
            ;;
        network)
            echo "wireshark nmap mtr mitmproxy mkcert ngrok"
            ;;
        ai)
            echo "ollama lm-studio gpt4all jan llama.cpp huggingface-cli"
            ;;
        databases)
            echo "postgresql@16 redis mysql sqlite dbeaver-community tableplus mongodb-compass"
            ;;
        browsers)
            echo "google-chrome firefox brave-browser arc firefox-developer-edition"
            ;;
        communication)
            echo "slack discord zoom microsoft-teams whatsapp telegram signal"
            ;;
        apps)
            echo "rectangle postman the-unarchiver raycast alfred notion obsidian insomnia bruno vlc bitwarden"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Add tools to auto-update list
add_auto_tools() {
    local tools="$1"

    mkdir -p "$STATE_DIR"
    touch "$AUTO_UPDATE_FILE"

    log_section "Adding Tools to Auto-Update"

    local tool_list=$(echo "$tools" | tr ',' ' ')

    for tool in $tool_list; do
        if grep -q "^${tool}$" "$AUTO_UPDATE_FILE" 2>/dev/null; then
            log_info "$tool is already in auto-update list"
        else
            echo "$tool" >> "$AUTO_UPDATE_FILE"
            log_success "Added: $tool"
        fi
    done

    echo ""
    show_auto_summary
}

# Add entire category to auto-update list
add_auto_category() {
    local category="$1"

    local tools=$(get_category_tools "$category")

    if [[ -z "$tools" ]]; then
        log_error "Unknown category: $category"
        log_info "Valid categories: terminal, editors, languages, git, devops, virtualization, cli, network, ai, databases, browsers, communication, apps"
        return 1
    fi

    mkdir -p "$STATE_DIR"
    touch "$AUTO_UPDATE_FILE"

    log_section "Adding Category to Auto-Update: $category"

    # Filter to only installed tools
    local installed_tools=""
    for tool in $tools; do
        if brew list "$tool" &>/dev/null 2>&1 || brew list --cask "$tool" &>/dev/null 2>&1 || command -v "$tool" &>/dev/null; then
            installed_tools="$installed_tools $tool"
        fi
    done

    if [[ -z "$installed_tools" ]]; then
        log_warning "No installed tools found in category: $category"
        return 0
    fi

    local added=0
    for tool in $installed_tools; do
        if grep -q "^${tool}$" "$AUTO_UPDATE_FILE" 2>/dev/null; then
            log_info "$tool already in list"
        else
            echo "$tool" >> "$AUTO_UPDATE_FILE"
            log_success "Added: $tool"
            ((added++))
        fi
    done

    echo ""
    log_success "Added $added tools from $category category"
    echo ""
    show_auto_summary
}

# Remove entire category from auto-update list
remove_auto_category() {
    local category="$1"

    local tools=$(get_category_tools "$category")

    if [[ -z "$tools" ]]; then
        log_error "Unknown category: $category"
        log_info "Valid categories: terminal, editors, languages, git, devops, virtualization, cli, network, ai, databases, browsers, communication, apps"
        return 1
    fi

    if [[ ! -f "$AUTO_UPDATE_FILE" ]]; then
        log_warning "Auto-update list not found"
        return 1
    fi

    log_section "Removing Category from Auto-Update: $category"

    local removed=0
    for tool in $tools; do
        if grep -q "^${tool}$" "$AUTO_UPDATE_FILE" 2>/dev/null; then
            sed -i '' "/^${tool}$/d" "$AUTO_UPDATE_FILE"
            log_success "Removed: $tool"
            ((removed++))
        fi
    done

    echo ""
    log_success "Removed $removed tools from $category category"
    echo ""
    show_auto_summary
}

# Remove tools from auto-update list
remove_auto_tools() {
    local tools="$1"

    if [[ ! -f "$AUTO_UPDATE_FILE" ]]; then
        log_warning "Auto-update list not found"
        return 1
    fi

    log_section "Removing Tools from Auto-Update"

    local tool_list=$(echo "$tools" | tr ',' ' ')

    for tool in $tool_list; do
        if grep -q "^${tool}$" "$AUTO_UPDATE_FILE" 2>/dev/null; then
            sed -i '' "/^${tool}$/d" "$AUTO_UPDATE_FILE"
            log_success "Removed: $tool"
        else
            log_info "$tool not in auto-update list"
        fi
    done

    echo ""
    show_auto_summary
}

# File to cache available tools scan
AVAILABLE_TOOLS_FILE="$STATE_DIR/available-tools.txt"

# Scan installed tools and save to cache file
scan_available_tools() {
    echo ""
    echo -e "${CYAN}Scanning installed tools...${NC}"

    local categories="system terminal editors languages git devops virtualization cli network ai databases browsers communication apps"
    local total_categories=$(echo "$categories" | wc -w | tr -d ' ')
    local current_cat=0

    # Get current auto-update tools
    local current_tools=""
    if [[ -f "$AUTO_UPDATE_FILE" ]]; then
        current_tools=$(grep -v "^#" "$AUTO_UPDATE_FILE" 2>/dev/null | grep -v "^$")
    fi

    # Clear and create cache file
    mkdir -p "$STATE_DIR"
    cat > "$AVAILABLE_TOOLS_FILE" << EOF
# Available tools for auto-update
# Generated: $(date)
# Format: category|tool
EOF

    local available_count=0

    for category in $categories; do
        ((current_cat++))
        printf "\r  [%d/%d] Scanning %s...          " "$current_cat" "$total_categories" "$category"

        local cat_tools=$(get_category_tools "$category")

        for tool in $cat_tools; do
            # Check if tool is installed
            if brew list "$tool" &>/dev/null 2>&1 || brew list --cask "$tool" &>/dev/null 2>&1; then
                # Check if NOT already in auto-update list
                if [[ -z "$current_tools" ]] || ! echo "$current_tools" | grep -q "^${tool}$"; then
                    echo "${category}|${tool}" >> "$AVAILABLE_TOOLS_FILE"
                    ((available_count++)) || true
                fi
            fi
        done
    done

    printf "\r  Scan complete! Found %d available tools.          \n" "$available_count"
    echo ""
}

# Show available tools from cache file
show_available_from_cache() {
    if [[ ! -f "$AVAILABLE_TOOLS_FILE" ]]; then
        echo -e "  ${YELLOW}(not scanned yet)${NC}"
        echo ""
        return 1
    fi

    local scan_date=$(grep "^# Generated:" "$AVAILABLE_TOOLS_FILE" 2>/dev/null | cut -d: -f2- | xargs)
    echo -e "  ${DIM}(last scan: ${scan_date})${NC}"
    echo ""

    local current_category=""
    local has_tools=false

    while IFS='|' read -r category tool || [[ -n "$category" ]]; do
        [[ "$category" =~ ^# ]] && continue
        [[ -z "$category" ]] && continue

        if [[ "$category" != "$current_category" ]]; then
            current_category="$category"
            echo -e "  ${CYAN}$category:${NC}"
        fi
        echo "    - $tool"
        has_tools=true
    done < "$AVAILABLE_TOOLS_FILE"

    if [[ "$has_tools" == false ]]; then
        echo "  (none - all installed tools are in auto-update list)"
    fi

    echo ""
    return 0
}

# Show brief auto-update summary (used after add/remove operations)
show_auto_summary() {
    echo -e "${BLUE}=== Auto-Update Summary ===${NC}"
    echo ""

    # Check if cron is enabled
    if crontab -l 2>/dev/null | grep -q "mac-dev-machine/cron-update.sh"; then
        local schedule=$(crontab -l 2>/dev/null | grep "mac-dev-machine/cron-update.sh" | awk '{print $1, $2, $3, $4, $5}')
        echo -e "  ${GREEN}Status:${NC}   Enabled"
        echo -e "  ${CYAN}Schedule:${NC} $schedule"
    else
        echo -e "  ${YELLOW}Status:${NC}   Disabled"
        echo -e "  ${CYAN}Enable:${NC}   ./update.sh --auto-enable"
    fi

    echo ""

    # Get current auto-update tools
    local current_tools=""
    if [[ -f "$AUTO_UPDATE_FILE" ]]; then
        current_tools=$(grep -v "^#" "$AUTO_UPDATE_FILE" 2>/dev/null | grep -v "^$" | sort)
    fi

    echo -e "${GREEN}Current Auto-Update List:${NC}"
    if [[ -n "$current_tools" ]]; then
        local count=$(echo "$current_tools" | wc -l | tr -d ' ')
        echo -e "  (${count} tools): $(echo $current_tools | tr '\n' ' ')"
    else
        echo "  (empty - will update ALL Homebrew packages)"
    fi

    echo ""
    echo "Run './update.sh --auto-list' to see available tools to add"
    echo ""
}

# Show auto-update configuration (full list with available tools)
show_auto_list() {
    echo ""
    echo -e "${BLUE}=== Auto-Update Configuration ===${NC}"
    echo ""

    # Check if cron is enabled
    if crontab -l 2>/dev/null | grep -q "mac-dev-machine/cron-update.sh"; then
        local schedule=$(crontab -l 2>/dev/null | grep "mac-dev-machine/cron-update.sh" | awk '{print $1, $2, $3, $4, $5}')
        echo -e "  ${GREEN}Status:${NC}   Enabled"
        echo -e "  ${CYAN}Schedule:${NC} $schedule"
    else
        echo -e "  ${YELLOW}Status:${NC}   Disabled"
        echo -e "  ${CYAN}Enable:${NC}   ./update.sh --auto-enable"
    fi

    echo ""

    # Get current auto-update tools
    local current_tools=""
    if [[ -f "$AUTO_UPDATE_FILE" ]]; then
        current_tools=$(grep -v "^#" "$AUTO_UPDATE_FILE" 2>/dev/null | grep -v "^$" | sort)
    fi

    # Always show that brew is auto-updated
    echo -e "${GREEN}Always Updated:${NC}"
    echo -e "  - brew (Homebrew itself - always runs 'brew update' first)"
    echo ""

    echo -e "${GREEN}Current Auto-Update List:${NC}"
    if [[ -n "$current_tools" ]]; then
        local count=$(echo "$current_tools" | wc -l | tr -d ' ')
        echo -e "  (${count} tools)"
        echo ""
        echo "$current_tools" | while read -r tool; do
            echo "  - $tool"
        done
    else
        echo "  (empty - will update ALL Homebrew packages)"
    fi

    echo ""
    echo -e "${YELLOW}Available to Add:${NC}"

    # Check if cache exists and show it
    if [[ -f "$AVAILABLE_TOOLS_FILE" ]]; then
        show_available_from_cache

        # Ask to rescan
        echo -n "Rescan for available tools? [y/N]: "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            scan_available_tools
            show_available_from_cache
        fi
    else
        echo "  (not scanned yet)"
        echo ""
        echo -n "Scan for available tools to add? [y/N]: "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            scan_available_tools
            show_available_from_cache
        fi
    fi

    echo -e "${CYAN}Quick Add Commands:${NC}"
    echo "  ./update.sh --auto-add <tool1,tool2>        # Add specific tools"
    echo "  ./update.sh --auto-add-category <category>  # Add entire category"
    echo "  ./update.sh --auto-scan                     # Rescan available tools"
    echo ""
    echo "  Categories: system, terminal, editors, languages, git, devops, virtualization,"
    echo "              cli, network, ai, databases, browsers, communication, apps"
    echo ""

    # Show recent log if exists
    if [[ -f "$AUTO_UPDATE_LOG" ]]; then
        echo -e "${CYAN}Recent Auto-Update Log:${NC}"
        local log_lines=$(tail -10 "$AUTO_UPDATE_LOG" 2>/dev/null)
        if [[ -n "$log_lines" ]]; then
            echo "$log_lines" | sed 's/^/  /'
        else
            echo "  (no recent updates)"
        fi
        echo ""
        echo "  Full log: $AUTO_UPDATE_LOG"
        echo ""
    fi
}

# Run auto-update manually (for testing) - shows output on screen
run_auto_update() {
    log_section "Running Auto-Update Manually"

    mkdir -p "$STATE_DIR"

    # Log header
    echo "========================================" | tee -a "$AUTO_UPDATE_LOG"
    echo "Manual auto-update: $(date)" | tee -a "$AUTO_UPDATE_LOG"
    echo "========================================" | tee -a "$AUTO_UPDATE_LOG"

    # Update Homebrew first
    echo ""
    echo -e "${CYAN}Updating Homebrew...${NC}"
    brew update 2>&1 | tee -a "$AUTO_UPDATE_LOG"

    # Check if we have a specific tool list
    if [[ -f "$AUTO_UPDATE_FILE" ]]; then
        local tools=$(grep -v "^#" "$AUTO_UPDATE_FILE" 2>/dev/null | grep -v "^$")

        if [[ -n "$tools" ]]; then
            echo ""
            echo -e "${CYAN}Updating tools from auto-update list...${NC}"
            echo ""

            while IFS= read -r tool || [[ -n "$tool" ]]; do
                [[ -z "$tool" ]] && continue

                echo -e "${BLUE}Updating:${NC} $tool"

                # Try formula first, then cask, then pip
                if brew list "$tool" &>/dev/null 2>&1; then
                    brew upgrade "$tool" 2>&1 | tee -a "$AUTO_UPDATE_LOG" || echo "  (already up to date)"
                elif brew list --cask "$tool" &>/dev/null 2>&1; then
                    brew upgrade --cask "$tool" 2>&1 | tee -a "$AUTO_UPDATE_LOG" || echo "  (already up to date)"
                elif pip3 show "$tool" &>/dev/null 2>&1; then
                    pip3 install --upgrade "$tool" 2>&1 | tee -a "$AUTO_UPDATE_LOG"
                elif npm list -g "$tool" &>/dev/null 2>&1; then
                    npm update -g "$tool" 2>&1 | tee -a "$AUTO_UPDATE_LOG"
                else
                    echo "  (not found, skipping)" | tee -a "$AUTO_UPDATE_LOG"
                fi
                echo ""
            done <<< "$tools"
        else
            echo ""
            echo -e "${CYAN}No specific tools in list - updating all Homebrew packages...${NC}"
            brew upgrade 2>&1 | tee -a "$AUTO_UPDATE_LOG"
            brew upgrade --cask 2>&1 | tee -a "$AUTO_UPDATE_LOG"
        fi
    else
        echo ""
        echo -e "${CYAN}No auto-update list found - updating all Homebrew packages...${NC}"
        brew upgrade 2>&1 | tee -a "$AUTO_UPDATE_LOG"
        brew upgrade --cask 2>&1 | tee -a "$AUTO_UPDATE_LOG"
    fi

    # Cleanup
    echo ""
    echo -e "${CYAN}Cleaning up...${NC}"
    brew cleanup 2>&1 | tee -a "$AUTO_UPDATE_LOG"

    echo ""
    echo "Auto-update completed: $(date)" | tee -a "$AUTO_UPDATE_LOG"
    echo ""
    log_success "Auto-update completed"
    echo ""
    echo "Full log: $AUTO_UPDATE_LOG"
}

# ============================================================================
# Standard Update Functions
# ============================================================================

# Update Homebrew
update_homebrew() {
    log_section "Updating Homebrew"

    log_step "Updating Homebrew itself..."
    brew update

    log_step "Upgrading formulae..."
    brew upgrade

    log_step "Upgrading casks..."
    brew upgrade --cask

    log_step "Cleaning up..."
    brew cleanup

    log_success "Homebrew update complete"
}

# Update language runtimes
update_languages() {
    log_section "Updating Language Runtimes"

    # Python via pyenv
    if command_exists pyenv; then
        log_step "Updating pyenv..."
        brew upgrade pyenv 2>/dev/null || true

        log_info "Current Python versions:"
        pyenv versions

        log_info "To install a new Python version: pyenv install <version>"
    fi

    # Node via nvm
    if [[ -d "$HOME/.nvm" ]]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        log_step "Checking for Node.js updates..."
        log_info "Current Node version: $(node --version 2>/dev/null || echo 'not installed')"

        log_info "To update Node.js: nvm install --lts"
    fi

    # Rust via rustup
    if command_exists rustup; then
        log_step "Updating Rust..."
        rustup update
        log_success "Rust updated"
    fi

    # Go
    if command_exists go; then
        log_step "Go update..."
        brew upgrade go 2>/dev/null || log_info "Go is up to date"
    fi

    # Ruby via rbenv
    if command_exists rbenv; then
        log_step "Updating rbenv..."
        brew upgrade rbenv ruby-build 2>/dev/null || true
        log_info "To update Ruby: rbenv install <version>"
    fi

    log_success "Language updates complete"
}

# Update NPM packages
update_npm() {
    log_section "Updating NPM Packages"

    if ! command_exists npm; then
        log_warning "NPM not found"
        return 1
    fi

    log_step "Updating npm itself..."
    npm install -g npm@latest

    log_step "Checking outdated global packages..."
    npm outdated -g || true

    log_step "Updating global packages..."
    npm update -g

    log_success "NPM update complete"
}

# Update pip packages
update_pip() {
    log_section "Updating Pip Packages"

    if ! command_exists pip3; then
        log_warning "pip3 not found"
        return 1
    fi

    log_step "Upgrading pip..."
    pip3 install --upgrade pip

    log_step "Checking outdated packages..."
    pip3 list --outdated | head -20

    log_info "To update all pip packages, run:"
    echo "  pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U"

    log_success "Pip check complete"
}

# Check for updates (dry run)
check_updates() {
    log_section "Checking for Updates"

    # Homebrew
    log_step "Checking Homebrew..."
    brew update >/dev/null 2>&1

    echo ""
    echo "=== Outdated Formulae ==="
    brew outdated --formula || echo "All formulae are up to date"

    echo ""
    echo "=== Outdated Casks ==="
    brew outdated --cask || echo "All casks are up to date"

    # NPM
    if command_exists npm; then
        echo ""
        echo "=== Outdated NPM Packages ==="
        npm outdated -g 2>/dev/null || echo "All npm packages are up to date"
    fi

    # Pip
    if command_exists pip3; then
        echo ""
        echo "=== Outdated Pip Packages ==="
        pip3 list --outdated 2>/dev/null | head -10 || echo "All pip packages are up to date"
    fi

    echo ""
    log_info "Run './update.sh' to apply all updates"
}

# Update all
update_all() {
    update_homebrew
    update_languages
    update_npm
    update_pip

    log_section "Update Complete"
    log_success "All tools have been updated"
}

# Main
main() {
    parse_args "$@"

    case $ACTION in
        help)
            show_help
            ;;
        brew)
            update_homebrew
            ;;
        languages)
            update_languages
            ;;
        npm)
            update_npm
            ;;
        pip)
            update_pip
            ;;
        check)
            check_updates
            ;;
        tools)
            update_tools "$TOOLS_LIST"
            ;;
        category)
            update_category "$CATEGORY"
            ;;
        auto-enable)
            enable_auto_update
            ;;
        auto-disable)
            disable_auto_update
            ;;
        auto-add)
            add_auto_tools "$AUTO_TOOLS"
            ;;
        auto-remove)
            remove_auto_tools "$AUTO_TOOLS"
            ;;
        auto-add-category)
            add_auto_category "$CATEGORY"
            ;;
        auto-remove-category)
            remove_auto_category "$CATEGORY"
            ;;
        auto-list)
            show_auto_list
            ;;
        auto-scan)
            scan_available_tools
            show_available_from_cache
            ;;
        auto-run)
            run_auto_update
            ;;
        all)
            update_all
            ;;
    esac
}

main "$@"
