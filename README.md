# Mac Dev Machine Setup

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-12%2B-blue.svg)](https://www.apple.com/macos/)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/devopz-ai/Mac-dev-machine/pulls)

A comprehensive automated setup for macOS development machines. This repository installs and configures everything a developer or DevOps engineer needs to be productive.

**Open Source** - Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Table of Contents

- [Quick Start](#quick-start)
- [Package Tiers](#package-tiers)
- [User Configuration](#user-configuration)
- [Update and Uninstall](#update-and-uninstall)
- [What Gets Installed](#what-gets-installed)
- [Language Setup Guide](#language-setup-guide)
- [Dotfiles Explained](#dotfiles-explained)
- [Manual Installation](#manual-installation)
- [Validation](#validation)
- [Troubleshooting](#troubleshooting)
- [For AI Agents](#for-ai-agents)

---

## Quick Start

### Automated Installation

```bash
# Clone the repository
git clone https://github.com/devopz-ai/Mac-dev-machine.git
cd Mac-dev-machine

# Make executable and run
chmod +x install.sh
./install.sh
```

The script will:
1. Detect your macOS version and architecture
2. Ask you to select a package tier (light/standard/advanced)
3. Install all tools for that package
4. Configure dotfiles (with backup of existing ones)
5. Save installation state for updates/uninstalls
6. Validate the installation

### See What's Available

```bash
./install.sh --show-packages
```

### Non-Interactive Mode

```bash
./install.sh --package standard --yes
```

---

## Supported macOS Versions

| Version | Codename | Architecture | Support |
|---------|----------|--------------|---------|
| 15.x | Sequoia | Intel & Apple Silicon | Full |
| 14.x | Sonoma | Intel & Apple Silicon | Full |
| 13.x | Ventura | Intel & Apple Silicon | Full |
| 12.x | Monterey | Intel & Apple Silicon | Limited |

Check your version: `sw_vers`

---

## Package Tiers

Choose the package that fits your needs:

### Light Package (~15 min, ~5GB)
**Best for:** Minimalists, limited disk space, specific use cases

| Category | Tools |
|----------|-------|
| System | Homebrew, Xcode CLI, Rosetta 2 |
| Terminal | iTerm2 |
| Editors | VS Code, Neovim |
| Languages | Python (pyenv), Node.js (nvm) |
| Git | Git, GitHub CLI |
| CLI Tools | jq, bat, ripgrep, fzf, htop |
| Browsers | Chrome, Firefox |

```bash
./install.sh --package light
```

### Standard Package (~30 min, ~15GB)
**Best for:** Most developers (recommended)

Everything in Light, plus:

| Category | Additional Tools |
|----------|-----------------|
| Terminal | + tmux, Starship, Oh My Zsh |
| Editors | + Cursor, PyCharm CE |
| Languages | + TypeScript, Go, Java, Rust |
| Git | + GitLab CLI, lazygit, git-delta |
| DevOps | Docker, kubectl, Helm, Terraform |
| CLI Tools | + yq, eza, fd, zoxide, wget, httpie |
| Browsers | + Brave |
| Databases | PostgreSQL, Redis, DBeaver |
| Communication | Slack, Discord, Zoom |
| Apps | Rectangle, Postman |

```bash
./install.sh --package standard
```

### Advanced Package (~60 min, ~30GB+)
**Best for:** Power users, DevOps engineers, AI/ML developers

Everything in Standard, plus:

| Category | Additional Tools |
|----------|-----------------|
| Editors | + IntelliJ, JetBrains Toolbox, Zed, Sublime |
| Languages | + Ruby, Bun, Deno |
| DevOps | + k9s, Minikube, Kind, Ansible, AWS/Azure/GCP CLIs |
| Network | Wireshark, nmap, ngrok, mitmproxy |
| AI Tools | Ollama, LM Studio, GPT4All, Aider, LiteLLM, OpenClaw |
| Databases | + MySQL, MongoDB, TablePlus |
| Communication | + WhatsApp, Telegram, Teams |
| Apps | + Raycast, Notion, Obsidian, Figma, VLC |

```bash
./install.sh --package advanced
```

---

## User Configuration

### Exclude Tools You Don't Want

Create a custom configuration to exclude specific tools:

```bash
# Copy the example config
cp config/user-config.yaml.example config/user-config.yaml

# Edit to exclude tools
nano config/user-config.yaml
```

Example `user-config.yaml`:
```yaml
package: standard

exclude:
  # Communication apps I don't need
  - slack
  - discord
  - microsoft-teams

  # Languages I don't use
  - ruby
  - rust

  # I prefer web version
  - whatsapp
```

Then run with your config:
```bash
./install.sh --config
```

---

## Update and Uninstall

### Update All Tools

```bash
# Check what needs updating
./update.sh --check

# Update everything
./update.sh

# Update only Homebrew packages
./update.sh --brew

# Update language runtimes
./update.sh --languages
```

### Uninstall Tools

```bash
# List installed tools
./uninstall.sh --list

# Remove a specific tool
./uninstall.sh --tool docker
./uninstall.sh --tool slack

# Remove all tools (careful!)
./uninstall.sh --all
```

### Installation State

The installer tracks what's installed in `~/.mac-dev-machine-state.yaml`. This file is used by:
- `update.sh` - to know what to update
- `uninstall.sh` - to know what can be removed
- `validate.sh` - to verify installation

---

## What Gets Installed

### System Essentials
- **Homebrew** - Package manager for macOS (like apt for Ubuntu)
- **Xcode Command Line Tools** - Compilers and build tools
- **Rosetta 2** - Runs Intel apps on Apple Silicon (M1/M2/M3)

### Terminals & Shell
- **iTerm2** - Better terminal than built-in Terminal.app
- **Oh My Zsh** - Framework for managing Zsh configuration
- **Starship** - Fast, customizable prompt
- **tmux** - Terminal multiplexer (multiple sessions in one window)

### Code Editors & IDEs
- **VS Code** - Microsoft's popular code editor
- **Cursor** - AI-powered code editor (VS Code fork)
- **PyCharm** - JetBrains Python IDE
- **IntelliJ IDEA** - JetBrains Java/Kotlin IDE
- **Neovim** - Modern Vim
- **Zed** - Fast, modern editor

### Programming Languages
See [Language Setup Guide](#language-setup-guide) for detailed explanations.

### DevOps Tools
- **Docker Desktop** - Container runtime
- **kubectl** - Kubernetes CLI
- **Helm** - Kubernetes package manager
- **Terraform** - Infrastructure as Code
- **AWS/Azure/GCP CLIs** - Cloud provider tools

### AI & LLM Tools
- **Claude Code** - Anthropic's AI coding assistant
- **Ollama** - Run LLMs locally
- **LiteLLM** - LLM proxy for multiple providers
- **OpenClaw** - AI legal/contract analysis
- **Aider** - AI pair programming

### Browsers
- **Google Chrome** - Primary browser
- **Firefox** - Privacy-focused browser
- **Firefox Developer Edition** - For web development
- **Brave** - Privacy browser with ad blocking
- **Arc** - Modern browser experience

### Communication
- **Slack** - Team messaging
- **Discord** - Community chat
- **WhatsApp** - Personal messaging
- **Zoom** - Video conferencing

---

## Language Setup Guide

This section explains how each programming language is set up and what beginners need to understand.

### Python

**What is Python?**
Python is a beginner-friendly programming language used for web development, data science, AI/ML, automation, and more.

**How we set it up:**
We use **pyenv** - a Python version manager that lets you install and switch between multiple Python versions.

```bash
# How pyenv works
pyenv install 3.12.0    # Install a specific version
pyenv global 3.12.0     # Set as default
pyenv local 3.11.0      # Use different version in a project folder
python --version        # Check current version
```

**Why pyenv instead of system Python?**
- macOS comes with Python, but it's outdated and used by the system
- Never modify system Python - it can break macOS
- pyenv lets you have multiple versions without conflicts

**After installation:**
```bash
# Create a virtual environment for your project
python -m venv myproject-env
source myproject-env/bin/activate

# Install packages
pip install requests flask pandas
```

**Key files created:**
- `~/.pyenv/` - Where Python versions are stored
- `~/.zshrc` - Updated with pyenv initialization

---

### Node.js (JavaScript/TypeScript)

**What is Node.js?**
Node.js runs JavaScript outside the browser. It's used for web servers, APIs, build tools, and command-line applications.

**How we set it up:**
We use **nvm** (Node Version Manager) to manage Node.js versions.

```bash
# How nvm works
nvm install 20          # Install Node.js v20 (LTS)
nvm use 20              # Switch to v20
nvm alias default 20    # Set v20 as default
node --version          # Check Node version
npm --version           # Check npm (package manager) version
```

**Why nvm?**
- Different projects may need different Node versions
- Easy to upgrade without breaking existing projects
- Avoids permission issues with global npm packages

**Package managers:**
- **npm** - Comes with Node.js (most common)
- **yarn** - Alternative, sometimes faster
- **pnpm** - Efficient disk space usage
- **bun** - Fast JavaScript runtime and package manager

**After installation:**
```bash
# Start a new project
mkdir myproject && cd myproject
npm init -y             # Create package.json
npm install express     # Install a package
```

**TypeScript:**
TypeScript is JavaScript with types. After Node.js is installed:
```bash
npm install -g typescript    # Install TypeScript compiler
tsc --version               # Check version
tsc myfile.ts               # Compile TypeScript to JavaScript
```

**Key files created:**
- `~/.nvm/` - Where Node versions are stored
- `~/.zshrc` - Updated with nvm initialization

---

### Java

**What is Java?**
Java is a widely-used language for enterprise applications, Android development, and backend services.

**How we set it up:**
We install **Eclipse Temurin** (formerly AdoptOpenJDK) - a free, open-source JDK.

```bash
# Check Java installation
java --version
javac --version          # Java compiler

# JAVA_HOME environment variable
echo $JAVA_HOME
```

**JDK vs JRE:**
- **JRE** (Java Runtime Environment) - Only runs Java programs
- **JDK** (Java Development Kit) - JRE + compiler + tools (this is what we install)

**Why Temurin?**
- Free and open source
- Long-term support (LTS) versions
- Production-ready, used by enterprises

**After installation:**
```bash
# Compile and run a Java file
javac HelloWorld.java    # Compile
java HelloWorld          # Run
```

**Key files created:**
- `~/.zshrc` - Updated with JAVA_HOME

---

### Go (Golang)

**What is Go?**
Go is a fast, simple language created by Google. Popular for cloud tools, APIs, and DevOps utilities.

**How we set it up:**
Direct installation via Homebrew.

```bash
# Check Go installation
go version

# Important directories
echo $GOPATH             # Where your Go projects live
echo $GOROOT             # Where Go is installed
```

**Go workspace:**
```
~/go/
├── bin/    # Compiled executables
├── pkg/    # Package objects
└── src/    # Source code (older style)
```

**Modern Go (with modules):**
```bash
# Start a new project
mkdir myproject && cd myproject
go mod init myproject    # Initialize module
go get github.com/gin-gonic/gin  # Add dependency
go build                 # Compile
go run main.go           # Run without compiling
```

**Key files created:**
- `~/.zshrc` - Updated with GOPATH and GOROOT

---

### Rust

**What is Rust?**
Rust is a systems programming language focused on safety and performance. Used for command-line tools, WebAssembly, and system software.

**How we set it up:**
We use **rustup** - the official Rust toolchain installer.

```bash
# Check Rust installation
rustc --version          # Compiler
cargo --version          # Package manager and build tool
```

**Why rustup?**
- Manages Rust versions and components
- Easy to update: `rustup update`
- Install additional tools: `rustup component add`

**After installation:**
```bash
# Create a new project
cargo new myproject
cd myproject
cargo build              # Compile
cargo run                # Compile and run
cargo test               # Run tests
```

**Key files created:**
- `~/.cargo/` - Cargo home directory
- `~/.rustup/` - Rustup toolchains
- `~/.zshrc` - Updated with cargo in PATH

---

### Ruby

**What is Ruby?**
Ruby is a dynamic language known for Ruby on Rails web framework.

**How we set it up:**
We use **rbenv** - a Ruby version manager.

```bash
# How rbenv works
rbenv install 3.3.0      # Install Ruby version
rbenv global 3.3.0       # Set as default
ruby --version           # Check version
gem --version            # Ruby package manager
```

**After installation:**
```bash
gem install rails        # Install Ruby on Rails
rails new myapp          # Create Rails application
```

**Key files created:**
- `~/.rbenv/` - Where Ruby versions are stored
- `~/.zshrc` - Updated with rbenv initialization

---

## Dotfiles Explained

**What are dotfiles?**
Dotfiles are configuration files that start with a `.` (dot). They're hidden by default in macOS Finder but control how your tools behave.

### Files We Configure

#### ~/.zshrc (Shell Configuration)

This file runs every time you open a terminal. We configure:

```bash
# PATH - Where your system looks for commands
export PATH="$HOME/.local/bin:$PATH"

# Aliases - Shortcuts for common commands
alias ll="ls -la"
alias gs="git status"
alias k="kubectl"

# Tool initialization
eval "$(pyenv init -)"           # Python
export NVM_DIR="$HOME/.nvm"      # Node.js
```

**Common customizations you might add:**
```bash
# Your custom aliases
alias myproject="cd ~/Projects/myproject"
alias serve="python -m http.server 8000"

# Your API keys (be careful with these!)
export OPENAI_API_KEY="sk-..."
```

#### ~/.gitconfig (Git Configuration)

Controls Git behavior:

```ini
[user]
    name = Your Name
    email = you@example.com

[init]
    defaultBranch = main

[alias]
    st = status
    co = checkout
    br = branch
    lg = log --oneline --graph

[pull]
    rebase = false

[core]
    editor = code --wait    # Use VS Code for commit messages
```

#### ~/.vimrc (Vim Configuration)

Basic Vim settings:

```vim
set number              " Show line numbers
set relativenumber      " Relative line numbers
set tabstop=4           " Tab width
set shiftwidth=4        " Indent width
set expandtab           " Use spaces instead of tabs
set autoindent          " Auto-indent new lines
syntax on               " Syntax highlighting
```

### Backup and Restore

The installer automatically backs up existing dotfiles:
```bash
# Backups are created as:
~/.zshrc.backup.20240115-143022

# To restore:
cp ~/.zshrc.backup.20240115-143022 ~/.zshrc
source ~/.zshrc
```

---

## Manual Installation

If you prefer to install tools manually, here are the commands:

### Step 1: Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Xcode Command Line Tools
```bash
xcode-select --install
```

### Step 3: Install Core Tools
```bash
# Editors
brew install --cask visual-studio-code cursor iterm2

# Languages
brew install pyenv nvm go rustup-init
brew install --cask temurin

# Git tools
brew install git gh glab lazygit

# DevOps
brew install --cask docker
brew install kubectl helm terraform

# Browsers
brew install --cask google-chrome firefox brave-browser

# Communication
brew install --cask slack discord whatsapp zoom

# AI Tools
brew install ollama
pip install litellm aider-chat open-interpreter
```

### Step 4: Configure Shell
Add to your `~/.zshrc`:
```bash
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust
source "$HOME/.cargo/env"
```

Then reload:
```bash
source ~/.zshrc
```

---

## Validation

After installation, verify everything works:

```bash
./tests/validate.sh
```

Or check manually:
```bash
# System
brew --version
xcode-select -p

# Languages
python --version
node --version
java --version
go version
rustc --version

# Tools
docker --version
kubectl version --client
terraform --version
gh --version
```

---

## Troubleshooting

### Homebrew Issues

**"Command not found: brew"**
```bash
# Apple Silicon (M1/M2/M3)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"

# Add to ~/.zshrc to make permanent
```

**Permission errors**
```bash
sudo chown -R $(whoami) $(brew --prefix)/*
```

### Python Issues

**"pyenv: command not found"**
```bash
# Add to ~/.zshrc
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
source ~/.zshrc
```

**Wrong Python version**
```bash
pyenv versions          # List installed versions
pyenv global 3.12.0     # Set global version
python --version        # Verify
```

### Node.js Issues

**"nvm: command not found"**
```bash
# Add to ~/.zshrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
source ~/.zshrc
```

### Docker Issues

**Docker daemon not running**
1. Open Docker Desktop app
2. Wait for it to start
3. Try again

**Permission denied**
```bash
# Add user to docker group (usually not needed on macOS)
sudo dscl . append /Groups/docker GroupMembership $(whoami)
```

### Git Issues

**"Please tell me who you are"**
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

---

## For AI Agents

See [CLAUDE.md](CLAUDE.md) for detailed instructions on:
- Running the installation script
- Module execution order
- Validation commands
- Error handling
- Adding new tools

---

## Browser Extensions (Recommended)

These must be installed manually from browser extension stores:

### For Chrome/Brave/Edge
- React Developer Tools
- Vue.js devtools
- Redux DevTools
- JSON Viewer
- Wappalyzer
- Lighthouse
- Octotree
- Refined GitHub
- Dark Reader
- 1Password / Bitwarden

### For Firefox
- All above (where available)
- Multi-Account Containers
- Firefox Relay

---

## Contributing

We welcome contributions from the community! Here's how you can help:

### Quick Contribution Guide

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your changes
4. **Make your changes** following our [style guidelines](CONTRIBUTING.md#style-guidelines)
5. **Test** your changes
6. **Submit a Pull Request**

### Ways to Contribute

| Contribution | Description |
|-------------|-------------|
| **Add a Tool** | Add a new tool to an existing module |
| **Report Bugs** | Found an issue? [Open a bug report](.github/ISSUE_TEMPLATE/bug_report.md) |
| **Request Tools** | Want a tool added? [Submit a request](.github/ISSUE_TEMPLATE/tool_request.md) |
| **Improve Docs** | Fix typos, add examples, improve clarity |
| **Test** | Test on different macOS versions and report results |

### Adding a New Tool

```bash
# 1. Find the right module in modules/
# 2. Add the installation command:
install_formula "tool-name" "Display Name"    # For brew formula
install_cask "tool-name" "Display Name"       # For GUI apps
install_pip "package-name" "Display Name"     # For Python packages

# 3. Add to config/packages.yaml under the right tier
# 4. Add validation to tests/validate.sh
# 5. Submit PR!
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Community

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Issue Templates](.github/ISSUE_TEMPLATE/)
- [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md)

---

## License

MIT License - Feel free to use, modify, and distribute. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- All [contributors](https://github.com/devopz-ai/Mac-dev-machine/graphs/contributors)
- [Homebrew](https://brew.sh/) for making macOS package management possible
- The open source community for all the amazing tools

---

## Star History

If you find this useful, please star the repository to help others discover it!
