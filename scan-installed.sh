#!/bin/bash
#
# Mac Dev Machine - Scan Installed Packages
# Scans and records currently installed packages
#
# Copyright (c) 2024-2026 Devopz.ai
# Author: Rashed Ahmed <rashed.ahmed@devopz.ai>
# License: MIT
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

# Draw progress bar
# Usage: draw_progress current total width label elapsed
draw_progress() {
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

# Run scan
run_scan() {
    log_section "Scanning installed packages..."

    # Initialize state directory
    mkdir -p "$STATE_DIR"

    # Clear existing state
    > "$STATE_FILE"

    local start_time=$(date +%s)

    # Known formulas we install
    local FORMULAS=(
        "git" "gh" "git-lfs" "lazygit" "glab" "git-delta" "tig" "git-flow"
        "wget" "curl" "httpie"
        "jq" "yq" "fx"
        "fzf" "ripgrep" "fd" "bat" "eza" "zoxide"
        "tree" "htop" "btop" "ncdu"
        "tmux" "neovim" "starship"
        "tldr" "thefuck" "shellcheck"
        "pyenv" "pyenv-virtualenv"
        "nvm"
        "go" "rustup-init"
        "rbenv" "ruby-build"
        "maven" "gradle"
        "docker" "docker-compose" "docker-buildx"
        "kubectl" "kubectx" "k9s" "helm" "minikube" "kind"
        "terraform" "terragrunt" "tfenv" "tflint" "packer"
        "pulumi" "ansible" "trivy"
        "awscli" "azure-cli"
        "postgresql@16" "mysql" "redis" "sqlite"
        "ffmpeg" "imagemagick"
        "chromedriver" "geckodriver"
        "openssl" "readline" "sqlite3" "xz" "zlib" "tcl-tk"
        "bun" "deno"
        "telnet" "nmap" "mtr" "mitmproxy" "mkcert"
        # Virtualization
        "vagrant" "qemu" "lima" "colima" "podman"
        # AI/ML Tools
        "ollama" "llama.cpp" "huggingface-cli" "qdrant" "milvus"
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
        "dbeaver-community" "tableplus" "mongodb-compass" "pgadmin4"
        "rectangle" "raycast" "alfred"
        "notion" "obsidian"
        "the-unarchiver" "appcleaner"
        "postman" "insomnia" "bruno"
        "vlc" "bitwarden" "keepassxc"
        "stats" "hiddenbar" "monitorcontrol"
        "wireshark" "ngrok"
        # Virtualization
        "virtualbox" "utm" "multipass"
        # AI/ML Tools
        "lm-studio" "gpt4all" "jan" "msty" "diffusionbee" "drawthings"
    )

    # NPM packages
    local NPM_PACKAGES=(
        "typescript" "ts-node" "yarn" "pnpm" "npm-check-updates"
        "playwright" "puppeteer" "web-ext" "@anthropic-ai/claude-code"
    )

    # PIP packages
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

    # Calculate totals
    local total_formulas=${#FORMULAS[@]}
    local total_casks=${#CASKS[@]}
    local total_npm=${#NPM_PACKAGES[@]}
    local total_pip=${#PIP_PACKAGES[@]}
    local grand_total=$((total_formulas + total_casks + total_npm + total_pip))

    echo ""
    echo -e "  ${CYAN}Scanning $total_formulas formulas, $total_casks casks, $total_npm npm, $total_pip pip packages...${NC}"
    echo ""

    local current=0
    local found_formulas=0
    local found_casks=0
    local found_npm=0
    local found_pip=0

    # Scan formulas
    for formula in "${FORMULAS[@]}"; do
        ((current++))
        local elapsed=$(( $(date +%s) - start_time ))
        draw_progress $current $grand_total 40 "$formula" $elapsed

        if brew list "$formula" &>/dev/null; then
            echo "formula|${formula}|${formula}|$(date +%Y-%m-%d_%H:%M:%S)" >> "$STATE_FILE"
            ((found_formulas++))
        fi
    done

    # Scan casks
    for cask in "${CASKS[@]}"; do
        ((current++))
        local elapsed=$(( $(date +%s) - start_time ))
        draw_progress $current $grand_total 40 "$cask" $elapsed

        if brew list --cask "$cask" &>/dev/null; then
            echo "cask|${cask}|${cask}|$(date +%Y-%m-%d_%H:%M:%S)" >> "$STATE_FILE"
            ((found_casks++))
        fi
    done

    # Scan npm packages
    if command -v npm &>/dev/null; then
        for pkg in "${NPM_PACKAGES[@]}"; do
            ((current++))
            local elapsed=$(( $(date +%s) - start_time ))
            draw_progress $current $grand_total 40 "$pkg" $elapsed

            if npm list -g "$pkg" &>/dev/null 2>&1; then
                echo "npm|${pkg}|${pkg}|$(date +%Y-%m-%d_%H:%M:%S)" >> "$STATE_FILE"
                ((found_npm++))
            fi
        done
    else
        current=$((current + total_npm))
    fi

    # Scan pip packages
    if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
        local pip_cmd="pip3"
        command -v pip3 &>/dev/null || pip_cmd="pip"

        for pkg in "${PIP_PACKAGES[@]}"; do
            ((current++))
            local elapsed=$(( $(date +%s) - start_time ))
            draw_progress $current $grand_total 40 "$pkg" $elapsed

            if $pip_cmd show "$pkg" &>/dev/null 2>&1; then
                echo "pip|${pkg}|${pkg}|$(date +%Y-%m-%d_%H:%M:%S)" >> "$STATE_FILE"
                ((found_pip++))
            fi
        done
    else
        current=$((current + total_pip))
    fi

    # Final summary
    local total_elapsed=$(( $(date +%s) - start_time ))
    echo ""
    echo ""

    log_section "Scan Complete"

    local total=$(wc -l < "$STATE_FILE" | tr -d ' ')

    echo ""
    echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}  SCAN RESULTS${NC}"
    echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "    Formulas found:  ${GREEN}$found_formulas${NC} / $total_formulas"
    echo -e "    Casks found:     ${GREEN}$found_casks${NC} / $total_casks"
    echo -e "    NPM found:       ${GREEN}$found_npm${NC} / $total_npm"
    echo -e "    Pip found:       ${GREEN}$found_pip${NC} / $total_pip"
    echo -e "    ─────────────────────────"
    echo -e "    ${CYAN}Total recorded:${NC}  ${GREEN}$total${NC} packages"
    echo ""
    echo -e "    ${BLUE}Time elapsed:${NC}    ${total_elapsed}s"
    echo -e "    ${BLUE}State file:${NC}      $STATE_FILE"
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
