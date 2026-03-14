#!/bin/bash
#
# Scan and record currently installed packages
# Run this to generate state file from existing installations
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

STATE_DIR="$HOME/.mac-dev-machine"
STATE_FILE="$STATE_DIR/installed.txt"

# Show help
show_help() {
    echo ""
    echo -e "${BLUE}Mac Dev Machine - Scan Installed Packages${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "Scans your system for packages installed by Mac Dev Machine"
    echo "and records them in the state file for tracking."
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  ./scan-installed.sh [OPTIONS]"
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo "  --run, -r       Run the scan"
    echo "  --show, -s      Show current state file contents"
    echo "  --clear, -c     Clear state file before scanning"
    echo "  --help, -h      Show this help"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  ./scan-installed.sh --run         # Scan and record packages"
    echo "  ./scan-installed.sh --show        # Show what's tracked"
    echo "  ./scan-installed.sh --clear --run # Clear and rescan"
    echo ""
    echo -e "${CYAN}State File:${NC}"
    echo "  $STATE_FILE"
    echo ""
}

# Show current state
show_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        log_warning "No state file found. Run --run to scan."
        exit 0
    fi

    local total=$(wc -l < "$STATE_FILE" | tr -d ' ')
    local formulas=$(grep "^formula|" "$STATE_FILE" | wc -l | tr -d ' ')
    local casks=$(grep "^cask|" "$STATE_FILE" | wc -l | tr -d ' ')
    local npms=$(grep "^npm|" "$STATE_FILE" | wc -l | tr -d ' ')
    local pips=$(grep "^pip|" "$STATE_FILE" | wc -l | tr -d ' ')

    echo ""
    echo -e "${GREEN}State File: $STATE_FILE${NC}"
    echo ""
    echo "  Formulas: $formulas"
    echo "  Casks:    $casks"
    echo "  NPM:      $npms"
    echo "  Pip:      $pips"
    echo "  ─────────"
    echo "  Total:    $total"
    echo ""
}

# Clear state file
clear_state() {
    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
        log_success "State file cleared"
    fi
}

# Run scan
run_scan() {
    log_section "Scanning installed packages..."

    # Initialize state directory
    mkdir -p "$STATE_DIR"

    # Clear existing state
    > "$STATE_FILE"

    # Known formulas we install
    local FORMULAS=(
        "git" "gh" "git-lfs" "lazygit"
        "wget" "curl" "httpie"
        "jq" "yq" "fx"
        "fzf" "ripgrep" "fd" "bat" "eza" "zoxide"
        "tree" "htop" "btop" "ncdu"
        "tmux" "neovim" "starship"
        "tldr" "thefuck"
        "pyenv" "pyenv-virtualenv"
        "nvm"
        "go" "rustup-init"
        "rbenv" "ruby-build"
        "maven" "gradle"
        "docker" "docker-compose" "docker-buildx"
        "kubectl" "kubectx" "k9s" "helm" "minikube" "kind"
        "terraform" "terragrunt" "tfenv" "tflint"
        "pulumi" "ansible"
        "awscli" "azure-cli"
        "postgresql@16" "mysql" "redis" "sqlite"
        "ffmpeg" "imagemagick"
        "ollama"
        "chromedriver" "geckodriver"
        "openssl" "readline" "sqlite3" "xz" "zlib" "tcl-tk"
        "bun" "deno"
    )

    # Known casks we install
    local CASKS=(
        "iterm2" "warp" "alacritty" "kitty"
        "visual-studio-code" "cursor" "zed" "sublime-text"
        "jetbrains-toolbox" "pycharm-ce" "intellij-idea-ce" "goland" "webstorm" "datagrip"
        "google-chrome" "firefox" "microsoft-edge"
        "firefox-developer-edition" "chromium"
        "brave-browser" "tor-browser"
        "arc" "opera"
        "docker"
        "lens"
        "google-cloud-sdk"
        "temurin"
        "slack" "discord" "zoom" "microsoft-teams"
        "telegram" "whatsapp" "signal"
        "lm-studio" "gpt4all" "jan" "msty"
        "dbeaver-community" "tableplus" "mongodb-compass" "pgadmin4"
        "rectangle" "raycast" "alfred"
        "notion" "obsidian"
        "the-unarchiver" "appcleaner"
        "postman" "insomnia" "bruno"
        "vlc" "bitwarden" "keepassxc"
        "stats" "hiddenbar" "monitorcontrol"
        "wireshark" "ngrok"
    )

    log_step "Scanning Homebrew formulas..."
    local count=0
    for formula in "${FORMULAS[@]}"; do
        if brew list "$formula" &>/dev/null; then
            echo "formula|${formula}|${formula}|$(date +%Y-%m-%d_%H:%M:%S)" >> "$STATE_FILE"
            ((count++))
        fi
    done
    log_success "Found $count formulas"

    log_step "Scanning Homebrew casks..."
    count=0
    for cask in "${CASKS[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            echo "cask|${cask}|${cask}|$(date +%Y-%m-%d_%H:%M:%S)" >> "$STATE_FILE"
            ((count++))
        fi
    done
    log_success "Found $count casks"

    log_step "Scanning npm global packages..."
    count=0
    if command -v npm &>/dev/null; then
        local NPM_PACKAGES=("typescript" "ts-node" "yarn" "pnpm" "npm-check-updates" "playwright" "puppeteer" "web-ext" "@anthropic-ai/claude-code")
        for pkg in "${NPM_PACKAGES[@]}"; do
            if npm list -g "$pkg" &>/dev/null 2>&1; then
                echo "npm|${pkg}|${pkg}|$(date +%Y-%m-%d_%H:%M:%S)" >> "$STATE_FILE"
                ((count++))
            fi
        done
    fi
    log_success "Found $count npm packages"

    log_step "Scanning pip packages..."
    count=0
    if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
        local pip_cmd="pip3"
        command -v pip3 &>/dev/null || pip_cmd="pip"

        local PIP_PACKAGES=(
            "pipx" "poetry" "black" "flake8" "mypy" "pytest" "ipython"
            "aider-chat" "open-interpreter" "shell-gpt"
            "litellm" "langchain" "langchain-community" "llama-index"
            "numpy" "pandas" "scipy" "scikit-learn" "torch" "transformers"
            "matplotlib" "jupyterlab"
            "openai" "anthropic" "google-generativeai"
            "chromadb" "pinecone-client"
            "selenium" "mycli" "pgcli" "litecli"
        )
        for pkg in "${PIP_PACKAGES[@]}"; do
            if $pip_cmd show "$pkg" &>/dev/null 2>&1; then
                echo "pip|${pkg}|${pkg}|$(date +%Y-%m-%d_%H:%M:%S)" >> "$STATE_FILE"
                ((count++))
            fi
        done
    fi
    log_success "Found $count pip packages"

    echo ""
    log_section "Scan Complete"

    local total=$(wc -l < "$STATE_FILE" | tr -d ' ')
    log_success "Total packages recorded: $total"
    log_info "State file: $STATE_FILE"
    echo ""
    log_info "You can now use ./uninstall.sh to manage these packages"
}

# Main
main() {
    # Show help if no arguments
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local do_clear=false
    local do_run=false
    local do_show=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --run|-r)
                do_run=true
                shift
                ;;
            --show|-s)
                do_show=true
                shift
                ;;
            --clear|-c)
                do_clear=true
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

    # Execute actions
    if $do_clear; then
        clear_state
    fi

    if $do_show; then
        show_state
        exit 0
    fi

    if $do_run; then
        run_scan
    else
        show_help
    fi
}

main "$@"
