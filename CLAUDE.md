# CLAUDE.md - AI Agent Instructions for Mac Dev Machine Setup

## Project Overview

This repository automates the setup of a macOS development machine for developers and DevOps engineers. The scripts detect the OS version, check installed tools, and install missing dependencies. It supports three package tiers (light/standard/advanced), user configuration for exclusions, and provides update/uninstall capabilities.

## Repository Structure

```
Mac-dev-machine/
├── install.sh              # Main installation script
├── update.sh               # Update installed tools
├── uninstall.sh            # Remove tools (with state tracking)
├── scan-installed.sh       # Scan and record installed packages
├── lib/                    # Shared functions
│   ├── utils.sh            # Logging, colors, helpers
│   ├── os_check.sh         # macOS version detection
│   ├── tool_check.sh       # Installation verification
│   └── state.sh            # Installation state tracking
├── modules/                # Modular installers (run in order)
│   ├── 01-system-essentials.sh
│   ├── 02-dev-tools.sh
│   ├── 03-languages.sh
│   ├── 04-devops-tools.sh
│   ├── 05-cli-tools.sh
│   ├── 06-network-tools.sh
│   ├── 07-communication.sh
│   ├── 08-ai-tools.sh
│   ├── 09-browsers.sh
│   ├── 10-databases.sh
│   └── 11-optional-apps.sh
├── config/
│   ├── packages.yaml           # Package tier definitions
│   ├── user-config.yaml.example # User customization template
│   ├── .install-state.yaml.example # State file example
│   └── dotfiles/               # Shell configuration templates
│       ├── .zshrc.template
│       ├── .gitconfig.template
│       └── .vimrc.template
├── tests/
│   └── validate.sh         # Post-install validation
└── logs/                   # Installation logs (gitignored)
```

## Package Tiers

The installer supports three package tiers:

| Tier | Description | Time | Disk |
|------|-------------|------|------|
| `light` | Essential tools only | ~15 min | ~5GB |
| `standard` | Recommended for most developers | ~30 min | ~15GB |
| `advanced` | Everything for power users | ~60 min | ~30GB+ |

### What's in Each Package

**Light:** Homebrew, iTerm2, VS Code, Neovim, Python, Node.js, Git, GitHub CLI, basic CLI tools, Chrome, Firefox

**Standard:** Light + Cursor, PyCharm, TypeScript, Go, Java, Rust, Docker, kubectl, Terraform, PostgreSQL, Redis, Slack, Discord, Zoom

**Advanced:** Standard + IntelliJ, all JetBrains tools, Ruby, Bun, all cloud CLIs, Wireshark, AI tools (Ollama, LM Studio, Aider, LiteLLM), MySQL, MongoDB, all communication apps

## How to Run Installation

### Show Available Packages
```bash
./install.sh --show-packages
```

### Package-Based Installation (AI Agent)
```bash
cd /path/to/Mac-dev-machine
chmod +x install.sh update.sh uninstall.sh

# Light package (minimal)
./install.sh --package light

# Standard package (recommended)
./install.sh --package standard

# Advanced package (everything)
./install.sh --package advanced
```

### Non-Interactive Mode
```bash
./install.sh --package standard --yes
```

### With User Configuration
```bash
# First, create user config
cp config/user-config.yaml.example config/user-config.yaml
# Edit to exclude tools as needed

# Then install with config
./install.sh --config
```

## Update Tools

```bash
# Check for available updates
./update.sh --check

# Update all tools
./update.sh

# Update specific categories
./update.sh --brew        # Homebrew packages only
./update.sh --languages   # Python, Node, Rust, etc.
./update.sh --npm         # Global npm packages
./update.sh --pip         # Python packages
```

## Uninstall Tools

The uninstall script tracks installations and only removes packages installed by this setup.

```bash
# Interactive mode - auto-scans if no state file exists
./uninstall.sh

# Show installed packages summary
./uninstall.sh --list

# Show detailed package list
./uninstall.sh --detailed

# Force rescan of installed packages
./uninstall.sh --scan

# Uninstall by type
./uninstall.sh --type formula    # Homebrew formulas
./uninstall.sh --type cask       # Homebrew casks
./uninstall.sh --type npm        # NPM packages
./uninstall.sh --type pip        # Pip packages

# Remove all (careful!)
./uninstall.sh --all
```

### Scan Installed Packages

If you need to regenerate the state file (e.g., after manual installations):
```bash
./scan-installed.sh
```

## Installation State

The installer tracks what's installed in `~/.mac-dev-machine/installed.txt`:

```
formula|git|git|2024-01-15_10:30:00
formula|wget|wget|2024-01-15_10:30:01
cask|visual-studio-code|Visual Studio Code|2024-01-15_10:31:00
cask|docker|Docker|2024-01-15_10:32:00
npm|typescript|typescript|2024-01-15_10:35:00
pip|aider-chat|Aider|2024-01-15_10:36:00
```

Format: `type|package|display_name|timestamp`

Use this state file to:
- Know what's installed by this setup
- Track what can be safely uninstalled
- Regenerate with `./scan-installed.sh` if needed

## Key Commands for AI Agents

### Check System Status
```bash
# Check macOS version
sw_vers

# Check architecture (Intel vs Apple Silicon)
uname -m

# Check if Homebrew is installed
which brew

# List installed brew packages
brew list

# List installed casks
brew list --cask

# Check installation state
cat ~/.mac-dev-machine-state.yaml
```

### Verify Tool Installation
```bash
# Quick validation
./tests/validate.sh --quick

# Full validation with versions
./tests/validate.sh --verbose

# Check specific tool
which <tool-name>
<tool-name> --version
```

### Module Execution
Each module can be run independently:
```bash
source lib/utils.sh
source lib/os_check.sh
source lib/tool_check.sh
source lib/state.sh
./modules/03-languages.sh
```

## Installation Order (Important)

Modules MUST run in numerical order due to dependencies:
1. `01-system-essentials.sh` - Homebrew (required by all others)
2. `02-dev-tools.sh` - Git, editors
3. `03-languages.sh` - Python, Node, etc. (some AI tools need these)
4. `04-devops-tools.sh` - Docker, K8s
5. `05-cli-tools.sh` - GitHub CLI, etc.
6. `06-network-tools.sh` - Wireshark, etc.
7. `07-communication.sh` - Slack, Discord
8. `08-ai-tools.sh` - Requires Python/Node from step 3
9. `09-browsers.sh` - Chrome, Firefox
10. `10-databases.sh` - PostgreSQL, Redis
11. `11-optional-apps.sh` - Utilities

## User Configuration

Users can exclude tools via `config/user-config.yaml`:

```yaml
package: standard

exclude:
  - slack
  - discord
  - ruby
  - rust

preferences:
  skip_dotfiles: false
  python_version: "3.12"
  node_version: "lts"
```

Check if a tool should be excluded:
```bash
# In module scripts, use:
if should_exclude "slack"; then
    log_info "Skipping slack (excluded by user)"
    return 0
fi
```

## Dotfiles Setup

The installer configures these dotfiles (with backup):
- `~/.zshrc` - Shell configuration, PATH, aliases, tool initialization
- `~/.gitconfig` - Git user settings and aliases
- `~/.vimrc` - Vim configuration

Backups are stored as `~/.zshrc.backup.<timestamp>`

The `.zshrc.template` includes:
- Homebrew initialization
- pyenv, nvm, rbenv setup
- JAVA_HOME, GOPATH, GOROOT
- Kubernetes aliases
- Useful CLI aliases (cat->bat, ls->eza)
- Custom functions (mkcd, extract, serve)

## Error Handling

- If a brew install fails, the script logs the error and continues
- Check `logs/install-<timestamp>.log` for details
- Run `./tests/validate.sh` to see what failed
- State file tracks successful installations

## Common Issues

### Homebrew on Apple Silicon
Homebrew installs to `/opt/homebrew` on Apple Silicon (M1/M2/M3) vs `/usr/local` on Intel. The scripts handle this automatically.

### Permission Issues
```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) $(brew --prefix)/*
```

### Xcode Command Line Tools
If prompted, install with:
```bash
xcode-select --install
```

## Adding New Tools

1. Add to appropriate module in `modules/`
2. Add to `config/packages.yaml` under correct tier
3. Add verification to `tests/validate.sh`
4. Update state tracking in `lib/state.sh` if needed

## Environment Variables Set by Dotfiles

After installation, these are configured in `~/.zshrc`:
- `PYENV_ROOT` - Python version manager
- `NVM_DIR` - Node version manager
- `GOPATH` - Go workspace
- `GOROOT` - Go installation
- `JAVA_HOME` - Java installation
- `PATH` - Updated with all tool locations

## Validation

Always run validation after installation:
```bash
# Quick check (essential tools)
./tests/validate.sh --quick

# Full check with versions
./tests/validate.sh --verbose
```

This checks:
- All expected tools are installed
- Tools are accessible in PATH
- Correct versions are installed
- Services can start (Docker, databases)
