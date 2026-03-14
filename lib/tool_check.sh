#!/bin/bash
#
# Tool installation verification functions
#

# Check if a tool is installed and get version
check_tool() {
    local tool="$1"
    local version_flag="${2:---version}"

    if command_exists "$tool"; then
        local version=$("$tool" $version_flag 2>&1 | head -n1)
        echo "$version"
        return 0
    else
        return 1
    fi
}

# Verify Homebrew installation
verify_homebrew() {
    if command_exists brew; then
        local version=$(brew --version | head -n1)
        log_success "Homebrew: $version"
        return 0
    else
        log_error "Homebrew is not installed"
        return 1
    fi
}

# Verify Xcode CLI tools
verify_xcode_cli() {
    if xcode-select -p &> /dev/null; then
        local path=$(xcode-select -p)
        log_success "Xcode CLI Tools: $path"
        return 0
    else
        log_error "Xcode CLI Tools not installed"
        return 1
    fi
}

# Verify Git
verify_git() {
    if command_exists git; then
        local version=$(git --version)
        log_success "Git: $version"
        return 0
    else
        log_error "Git is not installed"
        return 1
    fi
}

# Verify Python (pyenv)
verify_python() {
    if command_exists python3; then
        local version=$(python3 --version 2>&1)
        log_success "Python: $version"

        if command_exists pyenv; then
            local pyenv_version=$(pyenv --version)
            log_success "Pyenv: $pyenv_version"
        fi
        return 0
    else
        log_error "Python is not installed"
        return 1
    fi
}

# Verify Node.js (nvm)
verify_node() {
    # Source nvm if available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if command_exists node; then
        local version=$(node --version)
        log_success "Node.js: $version"

        if command_exists npm; then
            local npm_version=$(npm --version)
            log_success "npm: v$npm_version"
        fi
        return 0
    else
        log_error "Node.js is not installed"
        return 1
    fi
}

# Verify Java
verify_java() {
    if command_exists java; then
        local version=$(java --version 2>&1 | head -n1)
        log_success "Java: $version"
        return 0
    else
        log_error "Java is not installed"
        return 1
    fi
}

# Verify Go
verify_go() {
    if command_exists go; then
        local version=$(go version)
        log_success "Go: $version"
        return 0
    else
        log_error "Go is not installed"
        return 1
    fi
}

# Verify Rust
verify_rust() {
    if command_exists rustc; then
        local version=$(rustc --version)
        log_success "Rust: $version"

        if command_exists cargo; then
            local cargo_version=$(cargo --version)
            log_success "Cargo: $cargo_version"
        fi
        return 0
    else
        log_error "Rust is not installed"
        return 1
    fi
}

# Verify Docker
verify_docker() {
    if command_exists docker; then
        local version=$(docker --version)
        log_success "Docker: $version"

        # Check if Docker daemon is running
        if docker info &> /dev/null; then
            log_success "Docker daemon is running"
        else
            log_warning "Docker daemon is not running"
        fi
        return 0
    else
        log_error "Docker is not installed"
        return 1
    fi
}

# Verify kubectl
verify_kubectl() {
    if command_exists kubectl; then
        local version=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>&1 | head -n1)
        log_success "kubectl: $version"
        return 0
    else
        log_error "kubectl is not installed"
        return 1
    fi
}

# Verify Terraform
verify_terraform() {
    if command_exists terraform; then
        local version=$(terraform version | head -n1)
        log_success "Terraform: $version"
        return 0
    else
        log_error "Terraform is not installed"
        return 1
    fi
}

# Run all verifications
run_all_verifications() {
    log_section "Tool Verification"

    local failed=0

    # System
    verify_homebrew || ((failed++))
    verify_xcode_cli || ((failed++))

    # Version Control
    verify_git || ((failed++))

    # Languages
    verify_python || ((failed++))
    verify_node || ((failed++))
    verify_java || ((failed++))
    verify_go || ((failed++))
    verify_rust || ((failed++))

    # DevOps
    verify_docker || ((failed++))
    verify_kubectl || ((failed++))
    verify_terraform || ((failed++))

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_success "All tools verified successfully"
        return 0
    else
        log_warning "$failed tool(s) failed verification"
        return 1
    fi
}

# Check application installation (for GUI apps)
check_app_installed() {
    local app_name="$1"
    local app_path="/Applications/${app_name}.app"
    local user_app_path="$HOME/Applications/${app_name}.app"

    if [[ -d "$app_path" ]] || [[ -d "$user_app_path" ]]; then
        log_success "$app_name is installed"
        return 0
    else
        log_error "$app_name is not installed"
        return 1
    fi
}

# Verify editors
verify_editors() {
    echo ""
    log_info "Checking editors..."

    check_app_installed "Visual Studio Code"
    check_app_installed "Cursor"
    check_app_installed "iTerm"

    if command_exists nvim; then
        log_success "Neovim: $(nvim --version | head -n1)"
    fi
}

# Verify browsers
verify_browsers() {
    echo ""
    log_info "Checking browsers..."

    check_app_installed "Google Chrome"
    check_app_installed "Firefox"
    check_app_installed "Brave Browser"
    check_app_installed "Arc"
}

# Verify communication apps
verify_communication() {
    echo ""
    log_info "Checking communication apps..."

    check_app_installed "Slack"
    check_app_installed "Discord"
    check_app_installed "WhatsApp"
    check_app_installed "zoom.us"
}
