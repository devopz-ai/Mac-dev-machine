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

    if formula_installed "$formula"; then
        log_info "$name is already installed"
        return 0
    fi

    log_step "Installing $name..."
    if brew install "$formula" 2>&1; then
        log_success "$name installed"
        return 0
    else
        log_warning "Could not install $name (may need manual installation)"
        return 0  # Return 0 to continue installation
    fi
}

# Install brew cask if not installed
install_cask() {
    local cask="$1"
    local name="${2:-$cask}"

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
        return 0
    fi

    log_step "Installing $name..."
    if brew install --cask "$cask" 2>&1; then
        log_success "$name installed"
        return 0
    else
        log_warning "Could not install $name (may already exist or require manual install)"
        return 0  # Return 0 to continue installation
    fi
}

# Install npm global package
install_npm_global() {
    local package="$1"
    local name="${2:-$package}"

    if npm list -g "$package" &> /dev/null; then
        log_info "$name is already installed (npm)"
        return 0
    fi

    log_step "Installing $name via npm..."
    if npm install -g "$package"; then
        log_success "$name installed"
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
        return 0
    fi

    log_step "Installing $name via pip..."
    if pip3 install "$package"; then
        log_success "$name installed"
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
