#!/bin/bash
#
# Utility functions for Mac Dev Machine Setup
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${PURPLE}===================================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}===================================================================${NC}"
    echo ""
}

log_step() {
    echo -e "${CYAN}-->>${NC} $1"
}

# Ask user yes/no question
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "$AUTO_YES" == true ]]; then
        return 0
    fi

    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n]: " response
        case "$response" in
            [nN][oO]|[nN])
                return 1
                ;;
            *)
                return 0
                ;;
        esac
    else
        read -p "$prompt [y/N]: " response
        case "$response" in
            [yY][eE][sS]|[yY])
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Default timeout for network operations (in seconds)
INSTALL_TIMEOUT="${INSTALL_TIMEOUT:-300}"  # 5 minutes default

# Handle install failure - ask user what to do
# Returns: 0 = retry, 1 = skip, 2 = abort
handle_install_failure() {
    local name="$1"
    local error_msg="$2"

    # In auto mode, just skip
    if [[ "$AUTO_YES" == true ]]; then
        log_warning "Skipping $name (auto mode)"
        return 1
    fi

    echo ""
    log_error "Failed to install: $name"
    [[ -n "$error_msg" ]] && echo "  Error: $error_msg"
    echo ""
    echo "  Options:"
    echo "    [r] Retry installation"
    echo "    [s] Skip this package (continue with next)"
    echo "    [a] Abort installation"
    echo ""

    while true; do
        read -p "  What would you like to do? [r/s/a]: " choice
        case "$choice" in
            [rR]) return 0 ;;  # Retry
            [sS]) return 1 ;;  # Skip
            [aA])
                log_error "Installation aborted by user"
                exit 1
                ;;
            *)
                echo "  Please enter 'r' to retry, 's' to skip, or 'a' to abort"
                ;;
        esac
    done
}

# Install with timeout
install_with_timeout() {
    local timeout_sec="$1"
    shift
    local cmd="$@"

    # Use timeout command if available, otherwise just run
    if command_exists timeout; then
        timeout "$timeout_sec" $cmd
    elif command_exists gtimeout; then
        gtimeout "$timeout_sec" $cmd
    else
        # No timeout command, run directly
        $cmd
    fi
}

# Check if cask is installed
cask_installed() {
    brew list --cask "$1" &> /dev/null
}

# Check if formula is installed
formula_installed() {
    brew list "$1" &> /dev/null
}

# Install brew formula if not installed
install_formula() {
    local formula="$1"
    local name="${2:-$formula}"
    local max_retries=2
    local attempt=0

    if formula_installed "$formula"; then
        log_info "$name is already installed"
        record_install "formula" "$name" "$formula"
        return 0
    fi

    while [[ $attempt -lt $max_retries ]]; do
        log_step "Installing $name..."

        # Run brew install with output capture
        local output
        local exit_code
        output=$(brew install "$formula" 2>&1) && exit_code=0 || exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            log_success "$name installed"
            record_install "formula" "$name" "$formula"
            return 0
        fi

        # Check for network/timeout errors
        if echo "$output" | grep -qiE "(timed out|network|connection|curl|fetch|download)"; then
            log_warning "Network issue while installing $name"
            handle_install_failure "$name" "Network/download error"
            local action=$?
            case $action in
                0) ((attempt++)); continue ;;  # Retry
                1) return 0 ;;  # Skip
                2) exit 1 ;;    # Abort
            esac
        else
            # Non-network error
            log_warning "Could not install $name: $output"
            return 0  # Continue to next package
        fi
    done

    log_warning "Skipping $name after $max_retries attempts"
    return 0
}

# Install brew cask if not installed
install_cask() {
    local cask="$1"
    local name="${2:-$cask}"

    # Refresh sudo before cask install (some casks like temurin use sudo installer)
    refresh_sudo

    # Setup HOMEBREW_SUDO_ASKPASS if password is available but askpass not set
    if [[ -n "$SUDO_PASSWORD" ]] && [[ -z "$HOMEBREW_SUDO_ASKPASS" ]]; then
        local askpass_script=$(mktemp)
        chmod 700 "$askpass_script"
        cat > "$askpass_script" << ASKPASS_EOF
#!/bin/bash
echo "$SUDO_PASSWORD"
ASKPASS_EOF
        export SUDO_ASKPASS="$askpass_script"
        export HOMEBREW_SUDO_ASKPASS="$askpass_script"
    fi

    # Check if already installed via Homebrew
    if cask_installed "$cask"; then
        log_info "$name is already installed"
        return 0
    fi

    # Check if app already exists in /Applications (installed outside Homebrew)
    # Map common cask names to app names
    local app_name="$name"
    case "$cask" in
        iterm2) app_name="iTerm" ;;
        visual-studio-code) app_name="Visual Studio Code" ;;
        google-chrome) app_name="Google Chrome" ;;
        firefox) app_name="Firefox" ;;
        firefox-developer-edition) app_name="Firefox Developer Edition" ;;
        brave-browser) app_name="Brave Browser" ;;
        microsoft-edge) app_name="Microsoft Edge" ;;
        docker) app_name="Docker" ;;
        slack) app_name="Slack" ;;
        discord) app_name="Discord" ;;
        zoom) app_name="zoom.us" ;;
        spotify) app_name="Spotify" ;;
        notion) app_name="Notion" ;;
        obsidian) app_name="Obsidian" ;;
        postman) app_name="Postman" ;;
        insomnia) app_name="Insomnia" ;;
        dbeaver-community) app_name="DBeaver" ;;
        tableplus) app_name="TablePlus" ;;
        pycharm-ce) app_name="PyCharm CE" ;;
        intellij-idea-ce) app_name="IntelliJ IDEA CE" ;;
        webstorm) app_name="WebStorm" ;;
        goland) app_name="GoLand" ;;
        cursor) app_name="Cursor" ;;
        sublime-text) app_name="Sublime Text" ;;
        vlc) app_name="VLC" ;;
        whatsapp) app_name="WhatsApp" ;;
        telegram) app_name="Telegram" ;;
        signal) app_name="Signal" ;;
        microsoft-teams) app_name="Microsoft Teams" ;;
        lm-studio) app_name="LM Studio" ;;
        gpt4all) app_name="GPT4All" ;;
        jan) app_name="Jan" ;;
        arc) app_name="Arc" ;;
        raycast) app_name="Raycast" ;;
        rectangle) app_name="Rectangle" ;;
        alfred) app_name="Alfred 5" ;;
        the-unarchiver) app_name="The Unarchiver" ;;
        appcleaner) app_name="AppCleaner" ;;
        figma) app_name="Figma" ;;
        stats) app_name="Stats" ;;
        bitwarden) app_name="Bitwarden" ;;
        keepassxc) app_name="KeePassXC" ;;
        mongodb-compass) app_name="MongoDB Compass" ;;
        pgadmin4) app_name="pgAdmin 4" ;;
        jetbrains-toolbox) app_name="JetBrains Toolbox" ;;
        zed) app_name="Zed" ;;
        wireshark) app_name="Wireshark" ;;
        ngrok) app_name="ngrok" ;;
    esac

    if [[ -d "/Applications/${app_name}.app" ]] || [[ -d "$HOME/Applications/${app_name}.app" ]]; then
        log_info "$name is already installed (found in Applications)"
        record_install "cask" "$name" "$cask"
        return 0
    fi

    local max_retries=2
    local attempt=0

    while [[ $attempt -lt $max_retries ]]; do
        log_step "Installing $name..."

        # Refresh sudo right before brew install (some casks run sudo installer)
        refresh_sudo

        # Run brew install with output capture
        local output
        local exit_code
        output=$(brew install --cask "$cask" 2>&1) && exit_code=0 || exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            log_success "$name installed"
            record_install "cask" "$name" "$cask"
            return 0
        fi

        # Check for network/timeout errors
        if echo "$output" | grep -qiE "(timed out|network|connection|curl|fetch|download|mirror|server)"; then
            log_warning "Network issue while installing $name"
            handle_install_failure "$name" "Network/download error - try checking your internet connection"
            local action=$?
            case $action in
                0) ((attempt++)); continue ;;  # Retry
                1) return 0 ;;  # Skip
                2) exit 1 ;;    # Abort
            esac
        else
            # Non-network error (already installed, quarantine, etc)
            log_warning "Could not install $name (may already exist or require manual install)"
            echo "  Output: $output" | head -3
            return 0  # Continue to next package
        fi
    done

    log_warning "Skipping $name after $max_retries attempts"
    return 0
}

# Install npm global package
install_npm_global() {
    local package="$1"
    local name="${2:-$package}"

    if npm list -g "$package" &> /dev/null; then
        log_info "$name is already installed (npm)"
        record_install "npm" "$name" "$package"
        return 0
    fi

    log_step "Installing $name via npm..."
    if npm install -g "$package"; then
        log_success "$name installed"
        record_install "npm" "$name" "$package"
        return 0
    else
        log_error "Failed to install $name"
        return 1
    fi
}

# Install pip package
install_pip() {
    local package="$1"
    local name="${2:-$package}"

    if pip3 show "$package" &> /dev/null; then
        log_info "$name is already installed (pip)"
        record_install "pip" "$name" "$package"
        return 0
    fi

    log_step "Installing $name via pip..."
    if pip3 install "$package"; then
        log_success "$name installed"
        record_install "pip" "$name" "$package"
        return 0
    else
        log_error "Failed to install $name"
        return 1
    fi
}

# Get Homebrew prefix (differs between Intel and Apple Silicon)
get_brew_prefix() {
    if [[ -d "/opt/homebrew" ]]; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

# Run command with sudo - uses SUDO_PASSWORD if available
run_sudo() {
    if [[ -n "$SUDO_PASSWORD" ]]; then
        echo "$SUDO_PASSWORD" | sudo -S "$@" 2>/dev/null
    else
        sudo "$@"
    fi
}

# Refresh sudo timestamp - keeps sudo alive
refresh_sudo() {
    if [[ -n "$SUDO_PASSWORD" ]]; then
        # Refresh sudo with password
        if ! echo "$SUDO_PASSWORD" | sudo -S -v 2>/dev/null; then
            # If refresh failed, try without suppressing errors
            echo "$SUDO_PASSWORD" | sudo -S -v
        fi
    else
        sudo -v 2>/dev/null || true
    fi
}

# Source a file if it exists
source_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        source "$file"
    fi
}

# Retry a command with exponential backoff
retry_command() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    shift 2
    local command="$@"

    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if eval "$command"; then
            return 0
        fi

        log_warning "Attempt $attempt failed. Retrying in ${delay}s..."
        sleep "$delay"
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done

    log_error "Command failed after $max_attempts attempts"
    return 1
}

# Create directory if not exists
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Backup file with timestamp
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local timestamp=$(date +%Y%m%d-%H%M%S)
        cp "$file" "${file}.backup.${timestamp}"
        log_info "Backed up $file"
    fi
}

# Append to file if line not present
append_if_missing() {
    local file="$1"
    local line="$2"

    if ! grep -qF "$line" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
    fi
}

# ============================================================================
# State Management - Track installed packages
# ============================================================================

STATE_DIR="$HOME/.mac-dev-machine"
STATE_FILE="$STATE_DIR/installed.txt"

# Initialize state directory and file
init_state() {
    mkdir -p "$STATE_DIR"
    touch "$STATE_FILE"
}

# Record an installed package
# Usage: record_install "type" "name" "package"
# Example: record_install "formula" "Git" "git"
record_install() {
    local type="$1"
    local name="$2"
    local package="$3"
    local timestamp=$(date +%Y-%m-%d_%H:%M:%S)

    init_state

    # Check if already recorded
    if grep -q "^${type}|${package}|" "$STATE_FILE" 2>/dev/null; then
        return 0
    fi

    echo "${type}|${package}|${name}|${timestamp}" >> "$STATE_FILE"
}

# Remove a package from state
remove_from_state() {
    local type="$1"
    local package="$2"

    if [[ -f "$STATE_FILE" ]]; then
        local temp_file=$(mktemp)
        grep -v "^${type}|${package}|" "$STATE_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$STATE_FILE"
    fi
}

# Check if package is in our state (installed by us)
is_recorded() {
    local type="$1"
    local package="$2"

    grep -q "^${type}|${package}|" "$STATE_FILE" 2>/dev/null
}

# Get all installed packages of a type
get_installed_by_type() {
    local type="$1"
    grep "^${type}|" "$STATE_FILE" 2>/dev/null | cut -d'|' -f2 || true
}

# Get all installed packages
get_all_installed() {
    cat "$STATE_FILE" 2>/dev/null || true
}

# Count installed packages
count_installed() {
    wc -l < "$STATE_FILE" 2>/dev/null | tr -d ' ' || echo "0"
}
