#!/bin/bash
#
# Module 02: Development Tools
# Installs terminals, editors, and Git tools
#

set -e

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing development tools..."

# Install terminal tools
install_terminals() {
    log_step "Installing terminal tools..."

    # iTerm2 - Better terminal
    install_cask "iterm2" "iTerm2"

    # Terminal utilities
    install_formula "tmux" "tmux (terminal multiplexer)"
    install_formula "starship" "Starship (prompt)"
    install_formula "zsh-autosuggestions" "Zsh Autosuggestions"
    install_formula "zsh-syntax-highlighting" "Zsh Syntax Highlighting"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    log_step "Checking Oh My Zsh..."

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh My Zsh already installed"
        return 0
    fi

    log_step "Installing Oh My Zsh..."

    # Install without changing shell automatically
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    log_success "Oh My Zsh installed"
}

# Install code editors
install_editors() {
    log_step "Installing code editors..."

    # VS Code
    install_cask "visual-studio-code" "Visual Studio Code"

    # Cursor (AI-powered editor)
    install_cask "cursor" "Cursor"

    # JetBrains IDEs
    install_cask "jetbrains-toolbox" "JetBrains Toolbox"
    install_cask "pycharm-ce" "PyCharm Community Edition"
    install_cask "intellij-idea-ce" "IntelliJ IDEA Community Edition"

    # Neovim
    install_formula "neovim" "Neovim"

    # Zed (fast editor)
    install_cask "zed" "Zed"

    # Sublime Text
    install_cask "sublime-text" "Sublime Text"
}

# Install Git and related tools
install_git_tools() {
    log_step "Installing Git tools..."

    # Git
    install_formula "git" "Git"

    # Git LFS (Large File Storage)
    install_formula "git-lfs" "Git LFS"
    git lfs install 2>/dev/null || true

    # Git utilities
    install_formula "lazygit" "lazygit (Git TUI)"
    install_formula "git-delta" "delta (better diffs)"
    install_formula "gh" "GitHub CLI"
    install_formula "glab" "GitLab CLI"

    # Git extras
    install_formula "git-flow" "git-flow"
    install_formula "tig" "tig (Git viewer)"
}

# Install fonts (for terminals/editors)
install_fonts() {
    log_step "Installing developer fonts..."

    # Nerd Fonts (includes icons for terminal)
    install_cask "font-fira-code-nerd-font" "Fira Code Nerd Font" || true
    install_cask "font-jetbrains-mono-nerd-font" "JetBrains Mono Nerd Font" || true
    install_cask "font-hack-nerd-font" "Hack Nerd Font" || true
    install_cask "font-meslo-lg-nerd-font" "Meslo Nerd Font" || true

    log_success "Developer fonts installed"
}

# Install VS Code extensions (non-blocking)
install_vscode_extensions() {
    if ! command_exists code; then
        log_warning "VS Code CLI not found, skipping extensions"
        return 0
    fi

    log_step "Installing VS Code extensions..."

    local extensions=(
        "ms-python.python"
        "ms-vscode.vscode-typescript-next"
        "golang.go"
        "rust-lang.rust-analyzer"
        "redhat.java"
        "esbenp.prettier-vscode"
        "dbaeumer.vscode-eslint"
        "eamodio.gitlens"
        "github.copilot"
        "ms-azuretools.vscode-docker"
        "hashicorp.terraform"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
    )

    for ext in "${extensions[@]}"; do
        code --install-extension "$ext" --force 2>/dev/null || log_warning "Could not install $ext"
    done

    log_success "VS Code extensions installed"
}

# Main
main() {
    install_terminals
    install_oh_my_zsh
    install_editors
    install_git_tools
    install_fonts
    install_vscode_extensions

    log_success "Development tools completed"
}

main "$@"
