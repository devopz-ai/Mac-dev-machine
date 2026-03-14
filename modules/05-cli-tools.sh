#!/bin/bash
#
# Module 05: CLI Tools
# Installs various command-line utilities
#

set +e  # Continue on errors

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing CLI tools..."

# Install Git-related CLIs
install_git_clis() {
    log_step "Installing Git-related CLIs..."

    # GitHub CLI
    install_formula "gh" "GitHub CLI"

    # GitLab CLI
    install_formula "glab" "GitLab CLI"

    # Bitbucket CLI (if available)
    # Note: No official Homebrew formula

    # Configure GitHub CLI completion
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# GitHub CLI completion"
    append_if_missing "$shell_config" 'eval "$(gh completion -s zsh)"'

    log_success "Git CLIs completed"
}

# Install project management CLIs
install_project_clis() {
    log_step "Installing project management CLIs..."

    # Jira CLI
    install_formula "jira-cli" "Jira CLI"

    log_success "Project management CLIs completed"
}

# Install file and text utilities
install_file_utils() {
    log_step "Installing file and text utilities..."

    # JSON/YAML processing
    install_formula "jq" "jq (JSON processor)"
    install_formula "yq" "yq (YAML processor)"

    # Better cat
    install_formula "bat" "bat (better cat)"

    # Better ls
    install_formula "eza" "eza (better ls)"

    # Better find
    install_formula "fd" "fd (better find)"

    # Better grep
    install_formula "ripgrep" "ripgrep (rg)"

    # Fuzzy finder
    install_formula "fzf" "fzf"

    # Directory navigation
    install_formula "zoxide" "zoxide (smarter cd)"

    # Tree view
    install_formula "tree" "tree"

    # File watcher
    install_formula "watchman" "Watchman"
    install_formula "entr" "entr"

    # Disk usage
    install_formula "dust" "dust (better du)"
    install_formula "duf" "duf (better df)"
    install_formula "ncdu" "ncdu"

    # Configure aliases
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# CLI aliases"
    append_if_missing "$shell_config" 'alias cat="bat --paging=never"'
    append_if_missing "$shell_config" 'alias ls="eza"'
    append_if_missing "$shell_config" 'alias ll="eza -la"'
    append_if_missing "$shell_config" 'alias tree="eza --tree"'
    append_if_missing "$shell_config" 'eval "$(zoxide init zsh)"'

    log_success "File utilities completed"
}

# Install process utilities
install_process_utils() {
    log_step "Installing process utilities..."

    # Better top
    install_formula "htop" "htop"
    install_formula "btop" "btop"

    # Process management
    install_formula "procs" "procs (better ps)"

    log_success "Process utilities completed"
}

# Install archive utilities
install_archive_utils() {
    log_step "Installing archive utilities..."

    install_formula "p7zip" "7-Zip"
    install_formula "unrar" "unrar"
    install_formula "xz" "xz"
    install_formula "zstd" "zstd"

    log_success "Archive utilities completed"
}

# Install download utilities
install_download_utils() {
    log_step "Installing download utilities..."

    install_formula "wget" "wget"
    install_formula "curl" "curl"
    install_formula "aria2" "aria2"
    install_formula "httpie" "HTTPie"

    log_success "Download utilities completed"
}

# Install clipboard utilities
install_clipboard_utils() {
    log_step "Installing clipboard utilities..."

    install_formula "pbcopy" "pbcopy" || true  # Usually built-in
    install_formula "xclip" "xclip" || true

    log_success "Clipboard utilities completed"
}

# Install miscellaneous utilities
install_misc_utils() {
    log_step "Installing miscellaneous utilities..."

    # GNU utilities
    install_formula "coreutils" "GNU coreutils"
    install_formula "findutils" "GNU findutils"
    install_formula "gnu-sed" "GNU sed"
    install_formula "gnu-tar" "GNU tar"
    install_formula "gawk" "GNU awk"
    install_formula "grep" "GNU grep"

    # Other utilities
    install_formula "rename" "rename"
    install_formula "trash" "trash"
    install_formula "mas" "Mac App Store CLI"
    install_formula "tldr" "tldr (simplified man pages)"

    # Shell utilities
    install_formula "shellcheck" "ShellCheck"
    install_formula "shfmt" "shfmt"

    log_success "Miscellaneous utilities completed"
}

# Main
main() {
    install_git_clis
    install_project_clis
    install_file_utils
    install_process_utils
    install_archive_utils
    install_download_utils
    install_clipboard_utils
    install_misc_utils

    log_success "CLI tools completed"
}

main "$@"
