#!/bin/bash
#
# Module 03: Programming Languages
# Installs Python, Node.js, Java, Go, Rust, Ruby
#

set +e  # Continue on errors

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing programming languages..."

# Install Python via pyenv
install_python() {
    log_step "Installing Python (via pyenv)..."

    # Install pyenv
    install_formula "pyenv" "pyenv"
    install_formula "pyenv-virtualenv" "pyenv-virtualenv"

    # Install build dependencies first
    log_step "Installing Python build dependencies..."
    brew install openssl readline sqlite3 xz zlib tcl-tk 2>/dev/null || true

    # Configure pyenv in shell
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# Pyenv"
    append_if_missing "$shell_config" 'export PYENV_ROOT="$HOME/.pyenv"'
    append_if_missing "$shell_config" 'export PATH="$PYENV_ROOT/bin:$PATH"'
    append_if_missing "$shell_config" 'eval "$(pyenv init -)"'
    append_if_missing "$shell_config" 'eval "$(pyenv virtualenv-init -)"'

    # Initialize pyenv for current session (IMPORTANT: must do this before pyenv commands)
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
    eval "$(pyenv init --path)" 2>/dev/null || true

    # Get latest Python 3.12.x version or use default
    local python_version="3.12"
    log_step "Installing Python $python_version (latest patch version)..."

    # Use -s flag to skip if already installed
    if pyenv install -s "$python_version" 2>&1; then
        log_success "Python installed via pyenv"
    else
        log_warning "Could not install Python via pyenv, will use system Python"
    fi

    # Set global version
    pyenv global "$python_version" 2>/dev/null || pyenv global system

    # Rehash to update shims
    pyenv rehash 2>/dev/null || true

    # Verify Python is available
    if command -v python &>/dev/null; then
        log_success "Python $(python --version 2>&1) set as default"
    elif command -v python3 &>/dev/null; then
        log_info "Python available as 'python3': $(python3 --version 2>&1)"
        # Create alias for python -> python3
        append_if_missing "$shell_config" 'alias python="python3"'
        append_if_missing "$shell_config" 'alias pip="pip3"'
    fi

    # Upgrade pip
    log_step "Upgrading pip..."
    python -m pip install --upgrade pip setuptools wheel 2>/dev/null || \
    python3 -m pip install --upgrade pip setuptools wheel 2>/dev/null || true

    # Install essential Python packages
    log_step "Installing essential Python packages..."
    python -m pip install pipx poetry black flake8 mypy pytest ipython 2>/dev/null || \
    python3 -m pip install pipx poetry black flake8 mypy pytest ipython 2>/dev/null || true

    log_success "Python setup completed"
}

# Install Node.js via nvm
install_nodejs() {
    log_step "Installing Node.js (via nvm)..."

    # Install nvm
    install_formula "nvm" "nvm"

    # Configure nvm in shell
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# NVM"
    append_if_missing "$shell_config" 'export NVM_DIR="$HOME/.nvm"'
    append_if_missing "$shell_config" '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    append_if_missing "$shell_config" '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

    # Create NVM directory
    mkdir -p "$HOME/.nvm"

    # Initialize nvm for current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"

    # Install latest LTS Node.js
    log_step "Installing Node.js LTS..."
    nvm install --lts
    nvm alias default 'lts/*'

    log_success "Node.js $(node --version) installed"

    # Install global npm packages
    log_step "Installing global npm packages..."
    npm install -g typescript ts-node yarn pnpm npm-check-updates

    log_success "Node.js setup completed"
}

# Install Bun
install_bun() {
    log_step "Installing Bun..."
    install_formula "bun" "Bun"
    log_success "Bun setup completed"
}

# Install Deno
install_deno() {
    log_step "Installing Deno..."
    install_formula "deno" "Deno"
    log_success "Deno setup completed"
}

# Install Java (Temurin JDK)
install_java() {
    log_step "Installing Java (Temurin JDK)..."

    # Install latest Temurin JDK
    install_cask "temurin" "Eclipse Temurin JDK"

    # Configure JAVA_HOME
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# Java"
    append_if_missing "$shell_config" 'export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || echo "")'
    append_if_missing "$shell_config" 'export PATH="$JAVA_HOME/bin:$PATH"'

    # Install build tools
    install_formula "maven" "Maven"
    install_formula "gradle" "Gradle"

    log_success "Java setup completed"
}

# Install Go
install_go() {
    log_step "Installing Go..."

    install_formula "go" "Go"

    # Configure GOPATH
    local shell_config="$HOME/.zshrc"
    local gopath="$HOME/go"

    mkdir -p "$gopath/bin" "$gopath/src" "$gopath/pkg"

    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# Go"
    append_if_missing "$shell_config" "export GOPATH=\"$gopath\""
    append_if_missing "$shell_config" 'export GOROOT="$(brew --prefix go)/libexec"'
    append_if_missing "$shell_config" 'export PATH="$GOPATH/bin:$PATH"'

    # Install common Go tools
    export GOPATH="$gopath"
    export PATH="$GOPATH/bin:$PATH"

    log_step "Installing Go tools..."
    go install golang.org/x/tools/gopls@latest 2>/dev/null || true
    go install github.com/go-delve/delve/cmd/dlv@latest 2>/dev/null || true
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest 2>/dev/null || true

    log_success "Go setup completed"
}

# Install Rust
install_rust() {
    log_step "Installing Rust (via rustup)..."

    if command_exists rustc; then
        log_info "Rust already installed"
        rustup update 2>/dev/null || true
    else
        # Install rustup-init
        install_formula "rustup-init" "rustup-init"

        # Initialize Rust
        rustup-init -y --no-modify-path

        # Source cargo env
        source "$HOME/.cargo/env"
    fi

    # Configure shell
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# Rust"
    append_if_missing "$shell_config" 'source "$HOME/.cargo/env"'

    # Install common Rust tools
    log_step "Installing Rust tools..."
    rustup component add clippy rustfmt 2>/dev/null || true
    cargo install cargo-edit cargo-watch 2>/dev/null || true

    log_success "Rust setup completed"
}

# Install Ruby via rbenv
install_ruby() {
    log_step "Installing Ruby (via rbenv)..."

    install_formula "rbenv" "rbenv"
    install_formula "ruby-build" "ruby-build"

    # Configure rbenv in shell
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# Ruby"
    append_if_missing "$shell_config" 'eval "$(rbenv init -)"'

    # Initialize rbenv
    eval "$(rbenv init -)" 2>/dev/null || true

    # Install latest Ruby
    local ruby_version="3.3.0"
    log_step "Installing Ruby $ruby_version..."

    if rbenv versions | grep -q "$ruby_version"; then
        log_info "Ruby $ruby_version already installed"
    else
        rbenv install "$ruby_version"
    fi

    rbenv global "$ruby_version"

    # Install bundler
    gem install bundler

    log_success "Ruby setup completed"
}

# Main
main() {
    install_python
    install_nodejs
    install_bun
    install_deno
    install_java
    install_go
    install_rust
    install_ruby

    log_success "Programming languages completed"
}

main "$@"
