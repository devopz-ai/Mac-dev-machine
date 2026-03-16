# CLAUDE.md - AI Agent Instructions for Mac Dev Machine Setup

> **AI Agents**: This file tells you HOW to help users install and use this tool.
> For command references after installation, see `docs/AGENT_INDEX.md`.

---

## AGENTIC INSTALLATION GUIDE

Follow this step-by-step when helping a user set up their Mac.

### Step 1: Detect User's Situation

Ask or detect:
```
Q1: Is this a fresh Mac or existing setup?
Q2: What kind of development? (web, api, devops, ai/ml, data, mobile)
Q3: Do they want minimal or full setup?
```

### Step 2: Check Prerequisites

Run these checks BEFORE installation:

```bash
# Check macOS version (must be 11+)
sw_vers -productVersion

# Check architecture
uname -m
# arm64 = Apple Silicon (M1/M2/M3/M4)
# x86_64 = Intel

# Check if Xcode CLI tools installed
xcode-select -p
# If error: xcode-select --install

# Check disk space (need 5-30GB depending on package)
df -h /
```

### Step 3: Choose Package Tier

Guide user to choose based on their needs:

| User Says | Recommend | Why |
|-----------|-----------|-----|
| "Just starting", "minimal", "basic" | `light` | Essential tools, fast install |
| "Professional", "standard dev work" | `standard` | Most common tools, balanced |
| "Everything", "power user", "AI/ML" | `advanced` | Full suite including AI tools |
| "Not sure" | `standard` | Safe default for most devs |
| "Standard but no AI" | `standard --exclude ai` | Customize what you need |
| "Advanced but no chat apps" | `advanced --exclude communication` | Full suite minus extras |

**Help user exclude unwanted categories:**
```bash
# Show available categories
./install.sh --show-categories
```

### Step 4: Run Installation

```bash
# Navigate to repo (clone first if needed)
cd /path/to/Mac-dev-machine

# Make executable
chmod +x install.sh

# Run with chosen package
./install.sh --package <light|standard|advanced>

# For unattended (no prompts):
./install.sh --package standard --yes

# Exclude specific categories:
./install.sh --package standard --exclude ai
./install.sh --package standard --exclude ai,communication
./install.sh --package advanced --exclude ai,virtualization,browsers
```

**Available categories to exclude:**
- `terminal` - iTerm2, tmux, Starship, Warp, Alacritty
- `editors` - VS Code, Cursor, Neovim, PyCharm, IntelliJ
- `languages` - Python, Node.js, Go, Java, Rust, Ruby
- `git` - Git, GitHub CLI, GitLab CLI, lazygit
- `devops` - Docker, kubectl, Helm, Terraform, cloud CLIs
- `virtualization` - VirtualBox, Vagrant, UTM, QEMU, Lima, Colima
- `cli` - jq, bat, ripgrep, fzf, eza, htop, wget
- `network` - Wireshark, nmap, mitmproxy, ngrok
- `ai` - Ollama, LM Studio, GPT4All, LangChain, Aider
- `databases` - PostgreSQL, Redis, MySQL, DBeaver, TablePlus
- `browsers` - Chrome, Firefox, Brave, Arc
- `communication` - Slack, Discord, Zoom, Teams
- `apps` - Rectangle, Postman, Notion, Obsidian, Raycast

**Show all categories:**
```bash
./install.sh --show-categories
```

**Add excluded categories later (--only mode):**
```bash
# User previously ran: ./install.sh --package standard --exclude ai

# Later, to add AI tools:
./install.sh --package standard --only ai

# Add multiple categories:
./install.sh --package advanced --only ai,network,virtualization
```

The installer saves exclusion config to `~/.mac-dev-machine/config.txt` so it can suggest what to add later.

**Add specific tools by name (--add mode):**
```bash
# Add single tool
./install.sh --add ollama

# Add multiple tools
./install.sh --add ollama,lm-studio,jan

# Add tool not in predefined list (auto-detects formula/cask)
./install.sh --add some-new-tool

# Mix known and unknown tools
./install.sh --add ollama,htop,my-custom-tool
```

**Smart installation flow:**
1. Check if already installed (brew, PATH)
2. Check if in predefined list → install directly
3. Check if exists in Homebrew → auto-detect formula/cask
4. If not found anywhere → ask user for install method:
   - Homebrew tap (e.g., `user/repo`)
   - URL download (handles .pkg, .dmg, .zip, .tar.gz, .sh, binaries)
   - pip install (Python package)
   - npm install (Node package)
   - Custom command
   - Skip

Custom tools tracked in `~/.mac-dev-machine/custom-tools.txt` with install method.

**If user provides sudo password for full automation:**
```bash
export SUDO_PASSWORD="their-password"
./install.sh --package standard
```

### Step 5: Handle Installation Issues

**If installation hangs on a package:**
- Script will prompt: Retry (r) / Skip (s) / Abort (a)
- Recommend: Skip and install manually later

**If network error:**
```bash
# Check internet
ping -c 3 google.com

# Retry the installer
./install.sh --package <tier>
```

**If permission error:**
```bash
sudo chown -R $(whoami) $(brew --prefix)/*
# Then retry
```

### Step 6: Post-Installation Verification

ALWAYS run after installation completes:

```bash
# Reload shell (required!)
source ~/.zshrc

# Run validation
./tests/validate.sh

# Quick check for essentials only
./tests/validate.sh --quick
```

### Step 7: Handle Validation Warnings

If validation shows warnings:
1. Check if the warning tools are needed for user's workflow
2. If needed, copy the install commands shown in validation output
3. If not needed, ignore - warnings are optional tools

### Step 8: First-Use Setup

Guide user through first-time setup of key tools:

**Python:**
```bash
pyenv install 3.12
pyenv global 3.12
python --version  # Verify
```

**Node.js:**
```bash
nvm install 20
nvm alias default 20
node --version  # Verify
```

**Docker:**
```bash
open -a Docker  # Start Docker Desktop
# Wait 30 seconds
docker run hello-world  # Verify
```

**Git:**
```bash
git config --global user.name "User Name"
git config --global user.email "email@example.com"
```

---

## AGENTIC TROUBLESHOOTING GUIDE

When user reports an issue during or after installation:

### Error: "command not found: brew"
```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"

# Make permanent
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### Error: "command not found: <tool>"
```bash
# First, reload shell
source ~/.zshrc

# If still missing, install it
brew install <tool>        # CLI tools
brew install --cask <tool> # GUI apps
```

### Error: "Permission denied"
```bash
sudo chown -R $(whoami) $(brew --prefix)/*
chmod -R u+w $(brew --prefix)/*
```

### Error: "Xcode command line tools not found"
```bash
xcode-select --install
# Wait for installation popup, click Install
# After complete, retry the main installer
```

### Error: Package download timeout
```bash
# Check internet
ping -c 3 github.com

# If working, just retry
# The installer will prompt: [r]etry, [s]kip, [a]bort
```

### Error: "Cannot connect to Docker daemon"
```bash
# Start Docker Desktop
open -a Docker

# Wait 30 seconds, then verify
docker info
```

---

## AGENTIC CONVERSATION PATTERNS

### Pattern: User wants to install

```
User: "Help me set up my Mac for development"

Agent:
1. Ask: "What type of development? (web, api, devops, ai, data)"
2. Based on answer, recommend package tier
3. Provide exact commands:
   cd Mac-dev-machine
   ./install.sh --package <recommended>
4. After install: "Run ./tests/validate.sh to verify"
```

### Pattern: User has installation error

```
User: "Installation failed with error X"

Agent:
1. Identify error type from message
2. Look up fix in troubleshooting section above
3. Provide exact fix command
4. Say: "After fixing, run ./install.sh again to continue"
```

### Pattern: User unsure what to install

```
User: "What should I install?"

Agent:
1. Ask about their work type
2. Show package comparison:
   - light: basics (15min, 5GB)
   - standard: recommended (30min, 15GB)
   - advanced: everything (60min, 30GB)
3. Suggest: ./install.sh --show-packages
4. After they decide: ./install.sh --package <choice>
```

### Pattern: Post-install help

```
User: "Installation done, now what?"

Agent:
1. "First, reload your shell:"
   source ~/.zshrc
2. "Verify everything installed:"
   ./tests/validate.sh
3. "Set up your versions:"
   pyenv global 3.12
   nvm alias default 20
4. Based on their workflow, point to use-case guide
```

### Pattern: User wants to exclude categories

```
User: "I want standard but don't need AI stuff"

Agent:
./install.sh --package standard --exclude ai

User: "Install everything except chat apps and AI"

Agent:
./install.sh --package advanced --exclude ai,communication

User: "Just dev tools, no extras"

Agent:
./install.sh --package standard --exclude ai,communication,apps,browsers

User: "What categories can I exclude?"

Agent:
./install.sh --show-categories
```

**Category mapping for common requests:**
| User Request | Exclude Flag |
|--------------|--------------|
| "No AI" | `--exclude ai` |
| "No chat/communication apps" | `--exclude communication` |
| "No VMs/virtualization" | `--exclude virtualization` |
| "No browsers" | `--exclude browsers` |
| "No databases" | `--exclude databases` |
| "No extra apps" | `--exclude apps` |
| "No networking tools" | `--exclude network` |
| "Just code editors and languages" | `--exclude devops,virtualization,ai,databases,communication,network,apps` |

### Pattern: User wants to add excluded categories later

```
User: "I excluded AI earlier, now I want to add it"

Agent:
./install.sh --package standard --only ai

User: "What did I exclude before?"

Agent:
./install.sh --show-categories
# This will show previously excluded categories and suggest the command

User: "Add all the stuff I skipped"

Agent:
# Check config file for previous exclusions
cat ~/.mac-dev-machine/config.txt
# Then run with --only using those categories
./install.sh --package <tier> --only <excluded-categories>
```

**Config file location:** `~/.mac-dev-machine/config.txt`
- Tracks: package tier, excluded categories, install date
- Used by `--show-categories` to suggest what to add

### Pattern: User wants to add specific tools

```
User: "I need to add ollama and lm-studio"

Agent:
./install.sh --add ollama,lm-studio

User: "Install htop for me"

Agent:
./install.sh --add htop

User: "I found this tool called xyz, can you install it?"

Agent:
./install.sh --add xyz
# Smart detection flow:
# 1. Checks if already installed
# 2. Checks Homebrew (formula/cask)
# 3. If not found, prompts user:
#    - Homebrew tap
#    - URL download
#    - pip/npm package
#    - Custom command

User: "Install this tool from https://example.com/tool.tar.gz"

Agent:
./install.sh --add mytool
# When prompted, choose option 2 (URL download)
# Enter the URL, installer handles .pkg/.dmg/.zip/.tar.gz/.sh/binary

User: "What custom tools have I installed?"

Agent:
cat ~/.mac-dev-machine/custom-tools.txt
# Or run:
./install.sh --show-categories
# Shows custom tools at the bottom
```

**Files tracked:**
| File | Purpose |
|------|---------|
| `~/.mac-dev-machine/installed.txt` | All installed packages (formula/cask/pip/npm) |
| `~/.mac-dev-machine/config.txt` | Package tier, excluded categories |
| `~/.mac-dev-machine/custom-tools.txt` | Tools installed outside predefined list |
| `~/.mac-dev-machine/auto-update.txt` | Tools for automatic updates |
| `~/.mac-dev-machine/auto-update.log` | Auto-update cron log |
| `~/.mac-dev-machine/available-tools.txt` | Cached scan of tools available for auto-update |

**Version files (in repo):**
| File | Purpose |
|------|---------|
| `VERSION` | Current version number (e.g., "1.0.0") |
| `CHANGELOG.md` | Release history and changes |
| `scripts/version.sh` | Version bump, tagging, and release script |

### Pattern: User wants to update tools

```
User: "Update my tools"

Agent:
./update.sh --all                # Update everything

User: "Just update ollama and docker"

Agent:
./update.sh --tools ollama,docker

User: "Update all AI tools"

Agent:
./update.sh --category ai

User: "Set up automatic updates"

Agent:
# Enable weekly auto-updates (Saturday 9am)
./update.sh --auto-enable

# Add specific tools to auto-update
./update.sh --auto-add ollama,docker,visual-studio-code

# Check config (shows current list + available tools to add)
./update.sh --auto-list

User: "What tools can I add to auto-update?"

Agent:
./update.sh --auto-scan    # Scan and show available tools
# Or:
./update.sh --auto-list    # Shows config, prompts to scan if needed

User: "Auto-update all my AI tools"

Agent:
./update.sh --auto-enable              # Enable if not already
./update.sh --auto-add-category ai     # Add all AI tools

User: "Auto-update AI and DevOps but not browsers"

Agent:
./update.sh --auto-enable
./update.sh --auto-add-category ai
./update.sh --auto-add-category devops

User: "Stop auto-updating AI tools"

Agent:
./update.sh --auto-remove-category ai
```

### Pattern: User wants to uninstall tools

```
User: "Remove ollama"

Agent:
./uninstall.sh --tools ollama

User: "Uninstall all AI stuff"

Agent:
./uninstall.sh --category ai

User: "Remove all chat apps"

Agent:
./uninstall.sh --category communication

User: "What's installed?"

Agent:
./uninstall.sh --list      # Summary
./uninstall.sh --detailed  # Full list

User: "Remove everything"

Agent:
./uninstall.sh --all
# Requires typing 'yes' to confirm
```

### Pattern: Version and Release Management

```
User: "What version is this?"

Agent:
./install.sh --version
# Or: cat VERSION

User: "Create a new release"

Agent:
# For bug fixes (1.0.0 -> 1.0.1):
./scripts/version.sh --release patch

# For new features (1.0.0 -> 1.1.0):
./scripts/version.sh --release minor

# For breaking changes (1.0.0 -> 2.0.0):
./scripts/version.sh --release major

User: "Just bump version without releasing"

Agent:
./scripts/version.sh --bump patch    # Updates VERSION file only
./scripts/version.sh --bump minor
./scripts/version.sh --bump major

User: "Create and push a git tag"

Agent:
./scripts/version.sh --tag-push      # Creates v{version} tag and pushes to GitHub
```

**When to upgrade version (AI Agent Guidelines):**

| Change Type | Version Bump | Examples |
|-------------|--------------|----------|
| Bug fixes, typos, minor tweaks | `patch` | Fix validation bug, typo in docs |
| New features (backwards compatible) | `minor` | Add new tool, new category, new flag |
| Breaking changes | `major` | Change CLI interface, remove features |
| Documentation only | No bump | README updates (unless significant) |

**Release Process (what `--release` does):**
1. Bumps version in VERSION file
2. Updates CHANGELOG.md with new version section
3. Commits changes with "Release vX.Y.Z" message
4. Creates annotated git tag (vX.Y.Z)
5. Pushes commit and tag to GitHub

**Files involved:**
- `VERSION` - Single line with current version (e.g., "1.0.0")
- `CHANGELOG.md` - Release history and changes
- `scripts/version.sh` - Version management script

---

## Project Overview

This repository automates the setup of a macOS development machine for developers and DevOps engineers. The scripts detect the OS version, check installed tools, and install missing dependencies. It supports three package tiers (light/standard/advanced), user configuration for exclusions, and provides update/uninstall capabilities.

## Repository Structure

```
Mac-dev-machine/
├── install.sh              # Main installation script
├── update.sh               # Update installed tools
├── uninstall.sh            # Remove tools (with state tracking)
├── scan-installed.sh       # Scan and record installed packages
├── VERSION                 # Current version number
├── CHANGELOG.md            # Release history
├── scripts/
│   └── version.sh          # Version management and release script
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
├── docs/                   # Usage guides and documentation
│   ├── README.md               # Documentation index
│   ├── getting-started.md      # First steps after install
│   ├── tool-combinations.md    # Tools grouped by workflow
│   ├── ai-agent-guide.md       # AI assistant reference
│   ├── troubleshooting.md      # Common issues and fixes
│   └── use-cases/              # Workflow-specific guides
│       ├── web-development.md
│       ├── devops.md
│       ├── ai-ml.md
│       ├── api-development.md
│       ├── data-engineering.md
│       ├── mobile-development.md
│       ├── security-testing.md
│       └── virtualization.md
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

**Light:** Homebrew, iTerm2, VS Code, Neovim, Python, Node.js, Git, GitHub CLI, basic CLI tools, Chrome, Firefox, VirtualBox

**Standard:** Light + Cursor, PyCharm, TypeScript, Go, Java, Rust, Docker, kubectl, Terraform, Packer, Vagrant, Multipass, PostgreSQL, Redis, Slack, Discord, Zoom

**Advanced:** Standard + IntelliJ, all JetBrains tools, Ruby, Bun, all cloud CLIs, Wireshark, UTM, QEMU, Lima, Colima, Podman, AI tools (Ollama, LM Studio, GPT4All, Jan, llama.cpp, DiffusionBee, Draw Things, Aider, LangChain, Hugging Face CLI), Vector DBs (Qdrant, Milvus), MySQL, MongoDB, all communication apps

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

### Full Automation (No Prompts)
For completely unattended installation:
```bash
# Option 1: Environment variable (recommended)
export SUDO_PASSWORD="password"
./install.sh --package standard

# Option 2: Command-line argument
./install.sh --package standard --sudo-pass "password"
```

Features when password is provided:
- Sudo credentials cached at start
- All prompts auto-accepted
- Sudo kept alive throughout installation
- No user interaction required

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
./update.sh --brew              # Homebrew packages only
./update.sh --languages         # Python, Node, Rust, etc.
./update.sh --npm               # Global npm packages
./update.sh --pip               # Python packages

# Update specific tools
./update.sh --tools ollama,htop
./update.sh --category ai       # Update all AI tools

# Auto-update (cron)
./update.sh --auto-enable                    # Enable weekly auto-updates
./update.sh --auto-add ollama,docker         # Add tools to auto-update list
./update.sh --auto-add-category ai           # Add entire category to auto-update
./update.sh --auto-add-category devops       # Add all DevOps tools
./update.sh --auto-remove docker             # Remove from auto-update
./update.sh --auto-remove-category ai        # Remove category from auto-update
./update.sh --auto-list                      # Show auto-update config
./update.sh --auto-disable                   # Disable auto-updates
./update.sh --schedule "0 3 * * 0"           # Change to Sunday 3am
```

## Uninstall Tools

The uninstall script tracks installations and only removes packages installed by this setup.

```bash
# Interactive mode - auto-scans if no state file exists
./uninstall.sh --interactive

# Show installed packages summary
./uninstall.sh --list

# Show detailed package list
./uninstall.sh --detailed

# Uninstall specific tools
./uninstall.sh --tools ollama,htop,docker

# Uninstall by category
./uninstall.sh --category ai              # Remove all AI tools
./uninstall.sh --category communication   # Remove chat apps

# Uninstall by type
./uninstall.sh --type formula    # Homebrew formulas
./uninstall.sh --type cask       # Homebrew casks
./uninstall.sh --type npm        # NPM packages
./uninstall.sh --type pip        # Pip packages
./uninstall.sh --type custom     # Custom-installed tools

# Force rescan of installed packages
./uninstall.sh --scan

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

## Documentation Reference

For detailed usage guides, see `docs/` folder:

| Document | Description |
|----------|-------------|
| `docs/ai-agent-guide.md` | **Primary reference for AI agents** - commands, decision trees |
| `docs/tool-combinations.md` | Which tools work together by workflow |
| `docs/getting-started.md` | First steps after installation |
| `docs/troubleshooting.md` | Common issues and fixes |

### Use Case Guides

| Guide | When to Reference |
|-------|-------------------|
| `docs/use-cases/web-development.md` | Building web apps (React, Node, Python) |
| `docs/use-cases/devops.md` | Infrastructure, containers, K8s |
| `docs/use-cases/ai-ml.md` | Local LLMs, LangChain, RAG apps |
| `docs/use-cases/api-development.md` | REST/GraphQL APIs, testing |
| `docs/use-cases/data-engineering.md` | Databases, SQL, data pipelines |
| `docs/use-cases/virtualization.md` | VMs, Vagrant, UTM |

## Quick Command Reference for AI Agents

### Tool Installation
```bash
brew install <formula>           # CLI tool
brew install --cask <app>        # GUI app
pip install <package>            # Python package
npm install -g <package>         # Node global package
```

### Version Managers
```bash
pyenv install 3.12 && pyenv global 3.12   # Python
nvm install 20 && nvm alias default 20    # Node
```

### Local LLM
```bash
ollama pull llama2               # Download model
ollama run llama2                # Interactive chat
ollama serve                     # Start API server
```

### Containers
```bash
docker run -it <image>           # Run container
docker-compose up -d             # Start services
kubectl apply -f <file>          # Deploy to K8s
```

### Virtualization
```bash
vagrant init ubuntu/jammy64 && vagrant up   # VirtualBox VM
multipass launch --name dev                  # Quick Ubuntu VM
colima start                                 # Docker alternative
```

## Agentic Interaction Patterns

### User Intent Detection

Detect what the user needs from their message:

| Keywords in User Message | Intent | Action |
|--------------------------|--------|--------|
| "setup", "install", "new mac" | Initial Setup | Guide through `./install.sh` |
| "not working", "error", "failed" | Troubleshooting | Check `docs/troubleshooting.md` |
| "how do I", "how to" | Learning | Find command in `docs/ai-agent-guide.md` |
| "build", "create", "start project" | Project Start | Match to use-case guide |
| "missing", "not found" | Tool Missing | Provide `brew install` command |
| "update", "upgrade" | Maintenance | Guide through `./update.sh` |
| "remove", "uninstall" | Cleanup | Guide through `./uninstall.sh` |

### Response Workflow

```
1. DETECT intent from user message
2. VERIFY current state (what's installed, what's the error)
3. FIND relevant documentation section
4. PROVIDE specific commands (not general advice)
5. VERIFY success with check command
```

### Common User Scenarios

**Scenario: New Mac Setup**
```bash
# 1. Clone repo
git clone <repo-url> && cd Mac-dev-machine

# 2. Run installer (recommend standard for most users)
./install.sh --package standard

# 3. Verify installation
./tests/validate.sh

# 4. Reload shell
source ~/.zshrc
```

**Scenario: Tool Not Working**
```bash
# 1. Check if installed
which <tool>

# 2. If not found, reload shell
source ~/.zshrc

# 3. If still not found, install it
brew install <tool>  # or brew install --cask <tool>

# 4. Verify
<tool> --version
```

**Scenario: Start New Project**
```bash
# 1. AI detects project type from user description
# 2. Check required tools are installed
# 3. Provide scaffold commands from use-case guide
# 4. Offer to explain each step
```

### Proactive Suggestions

When user completes an action, suggest next steps:

| After | Suggest |
|-------|---------|
| Installation completes | "Run `./tests/validate.sh` to verify" |
| Validation shows warnings | "Copy the install commands shown to add missing tools" |
| User creates Python project | "Consider creating a virtual env: `python -m venv .venv`" |
| User starts Docker container | "View logs with `docker logs -f <container>`" |
| User mentions AI/LLM | "Try `ollama run llama2` for local inference" |

### Error Recovery Patterns

When user encounters an error:

1. **Parse the error message** - identify tool and error type
2. **Check known fixes** - reference `docs/troubleshooting.md`
3. **Provide exact fix command** - not general advice
4. **Verify the fix** - always end with a verification command

Example:
```
User: "docker: command not found"
Agent:
1. Docker CLI not in PATH
2. Fix: source ~/.zshrc
3. If still missing: brew install docker
4. Verify: docker --version
5. Start Docker Desktop: open -a Docker
```
