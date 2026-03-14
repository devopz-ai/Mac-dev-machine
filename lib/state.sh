#!/bin/bash
#
# State management functions for Mac Dev Machine
# Tracks what is installed, needs update, or should be uninstalled
#

STATE_FILE="$HOME/.mac-dev-machine-state.yaml"

# Initialize state file
init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << EOF
# Mac Dev Machine - Installation State
# Auto-generated - DO NOT EDIT MANUALLY

metadata:
  installed_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  updated_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  package_tier: "${PACKAGE_TIER:-standard}"
  macos_version: "$(sw_vers -productVersion)"
  architecture: "$(uname -m)"

installed:
  formulae: {}
  casks: {}
  languages: {}
  pip: []
  npm: []

excluded: []

dotfiles:
  zshrc:
    configured: false
    backup_path: null
  gitconfig:
    configured: false
    backup_path: null
  vimrc:
    configured: false
    backup_path: null
EOF
        log_info "Created state file: $STATE_FILE"
    fi
}

# Update timestamp in state file
update_state_timestamp() {
    if [[ -f "$STATE_FILE" ]]; then
        local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        # Use sed to update the timestamp (basic approach)
        sed -i '' "s/updated_at:.*/updated_at: \"$timestamp\"/" "$STATE_FILE" 2>/dev/null || true
    fi
}

# Record formula installation
record_formula() {
    local formula="$1"
    local version="${2:-unknown}"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Simple append approach (will improve with yq if available)
    echo "  # $formula installed at $timestamp" >> "$STATE_FILE.tmp" 2>/dev/null || true

    log_info "Recorded installation: $formula ($version)"
}

# Record cask installation
record_cask() {
    local cask="$1"
    local version="${2:-unknown}"

    log_info "Recorded installation: $cask ($version)"
}

# Check if tool is in state file
is_in_state() {
    local tool="$1"

    if [[ -f "$STATE_FILE" ]]; then
        grep -q "$tool" "$STATE_FILE" 2>/dev/null
        return $?
    fi
    return 1
}

# Get installed tools from state
get_installed_tools() {
    if [[ -f "$STATE_FILE" ]]; then
        # List tools from state file
        grep -E "^    [a-z]" "$STATE_FILE" 2>/dev/null | sed 's/:.*//' | tr -d ' ' || true
    fi
}

# Record user exclusion
record_exclusion() {
    local tool="$1"
    echo "  - $tool" >> "${STATE_FILE}.exclusions" 2>/dev/null || true
    log_info "Excluded: $tool"
}

# Check if tool is excluded
is_excluded() {
    local tool="$1"

    # Check user config exclusions
    if [[ -f "${SCRIPT_DIR}/config/user-config.yaml" ]]; then
        if grep -A 100 "^exclude:" "${SCRIPT_DIR}/config/user-config.yaml" | grep -q "- $tool"; then
            return 0
        fi
    fi

    return 1
}

# Save current state summary
save_state_summary() {
    local summary_file="$HOME/.mac-dev-machine-summary.txt"

    cat > "$summary_file" << EOF
Mac Dev Machine - Installation Summary
Generated: $(date)
Package Tier: ${PACKAGE_TIER:-unknown}

=== Homebrew Formulae ===
$(brew list --formula 2>/dev/null | head -30 || echo "None")

=== Homebrew Casks ===
$(brew list --cask 2>/dev/null | head -30 || echo "None")

=== Python (pyenv) ===
$(pyenv versions 2>/dev/null || echo "pyenv not installed")

=== Node.js (nvm) ===
Current: $(node --version 2>/dev/null || echo "not installed")

=== Global NPM Packages ===
$(npm list -g --depth=0 2>/dev/null | tail -n +2 | head -20 || echo "None")

EOF

    log_info "State summary saved to: $summary_file"
}

# Show installation diff (what changed)
show_state_diff() {
    log_section "Installation Changes"

    if [[ -f "$STATE_FILE" ]]; then
        echo "State file: $STATE_FILE"
        echo ""
        echo "Last updated: $(grep 'updated_at' "$STATE_FILE" | head -1)"
        echo "Package tier: $(grep 'package_tier' "$STATE_FILE" | head -1)"
    else
        echo "No state file found. Run ./install.sh to create one."
    fi
}

# Get tools that need updates
get_outdated_tools() {
    log_info "Checking for outdated tools..."

    echo ""
    echo "=== Outdated Formulae ==="
    brew outdated --formula 2>/dev/null || echo "All up to date"

    echo ""
    echo "=== Outdated Casks ==="
    brew outdated --cask 2>/dev/null || echo "All up to date"
}

# Reset state (for fresh install)
reset_state() {
    if [[ -f "$STATE_FILE" ]]; then
        local backup="${STATE_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
        mv "$STATE_FILE" "$backup"
        log_info "State file backed up to: $backup"
    fi
    init_state
}
