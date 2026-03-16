# AI Agent Index

> **Purpose**: Machine-readable index for AI assistants helping users with Mac Dev Machine setup.
> **Read this first** before answering user questions about this tool.

## Quick Context

This tool automates macOS developer environment setup. Users run `./install.sh --package [light|standard|advanced]` to install development tools.

## Intent Router

Map user questions to the right documentation:

| User Intent | Primary Doc | Fallback |
|-------------|-------------|----------|
| "Install/setup my Mac" | `CLAUDE.md` | `getting-started.md` |
| "What tools do I need for X" | `tool-combinations.md` | `use-cases/*.md` |
| "How do I use X" | `ai-agent-guide.md` | `use-cases/*.md` |
| "Something isn't working" | `troubleshooting.md` | `ai-agent-guide.md#error-handling` |
| "Build web app" | `use-cases/web-development.md` | - |
| "Build API" | `use-cases/api-development.md` | - |
| "DevOps/containers/K8s" | `use-cases/devops.md` | - |
| "AI/ML/LLM project" | `use-cases/ai-ml.md` | - |
| "Database work" | `use-cases/data-engineering.md` | - |
| "Virtual machines" | `use-cases/virtualization.md` | - |
| "Security testing" | `use-cases/security-testing.md` | - |
| "Mobile app" | `use-cases/mobile-development.md` | - |

## Command Quick Reference

### Installation
```bash
./install.sh --package light      # Minimal (~15min)
./install.sh --package standard   # Recommended (~30min)
./install.sh --package advanced   # Everything (~60min)
./install.sh --show-packages      # See what's included
./install.sh --show-categories    # See categories for exclusion
```

### Exclude Categories
```bash
./install.sh --package standard --exclude ai
./install.sh --package standard --exclude ai,communication
./install.sh --package advanced --exclude ai,virtualization,browsers
```

### Add Categories Later (--only mode)
```bash
# User previously excluded AI, now wants to add it:
./install.sh --package standard --only ai

# Add multiple categories:
./install.sh --package advanced --only ai,network

# Show what was previously excluded:
./install.sh --show-categories
```

### Add Specific Tools (--add mode)
```bash
# Add single tool by name
./install.sh --add ollama

# Add multiple tools
./install.sh --add ollama,lm-studio,jan

# Add tool not in predefined list (smart detection)
./install.sh --add some-new-tool
```

**Smart install flow for unknown tools:**
1. Check Homebrew (formula/cask)
2. If not found, prompt user:
   - `1` Homebrew tap (user/repo)
   - `2` URL download (.pkg/.dmg/.zip/.tar.gz/.sh/binary)
   - `3` pip install
   - `4` npm install
   - `5` Custom command
   - `6` Skip

**Categories:** system, terminal, editors, languages, git, devops, virtualization, cli, network, ai, databases, browsers, communication, apps

### Validation
```bash
./tests/validate.sh               # Full check
./tests/validate.sh --quick       # Essential only
./tests/validate.sh --verbose     # With versions
```

### Update Tools
```bash
./update.sh                           # Show help
./update.sh --all                     # Update everything
./update.sh --tools ollama,docker     # Update specific tools
./update.sh --category ai             # Update category
./update.sh --check                   # Check for updates (dry run)
```

### Auto-Update (Cron)
```bash
./update.sh --auto-enable               # Enable weekly auto-updates
./update.sh --auto-add ollama,docker    # Add tools to auto-update
./update.sh --auto-add-category ai      # Add entire category
./update.sh --auto-add-category devops  # Add all DevOps tools
./update.sh --auto-remove-category ai   # Remove category
./update.sh --auto-list                 # Show config (prompts to scan)
./update.sh --auto-scan                 # Scan for available tools to add
./update.sh --auto-disable              # Disable
```

**`--auto-list` shows:**
- Current auto-update status and schedule
- Tools in auto-update list
- Prompts to scan for available tools (cached after first scan)

**`--auto-scan`:** Scans installed tools with progress, shows what can be added

### Uninstall Tools
```bash
./uninstall.sh                        # Show help + installed summary
./uninstall.sh --list                 # Show installed details
./uninstall.sh --tools ollama,htop    # Uninstall specific tools
./uninstall.sh --category ai          # Uninstall category
./uninstall.sh --all                  # Uninstall everything
```

### Scan Installed Packages
```bash
./install.sh --scan                   # Scan with time estimate + confirmation
./uninstall.sh --scan                 # Same as above
./scan-installed.sh -r                # Direct scan (no prompt)
```

### Version Management
```bash
./install.sh --version                # Show version
./scripts/version.sh                  # Show detailed version info
./scripts/version.sh --bump patch     # Bump 1.0.0 -> 1.0.1
./scripts/version.sh --bump minor     # Bump 1.0.0 -> 1.1.0
./scripts/version.sh --bump major     # Bump 1.0.0 -> 2.0.0
./scripts/version.sh --tag-push       # Create and push git tag
./scripts/version.sh --release patch  # Full release (bump, commit, tag, push)
```

**Version bump guide:**
- `patch` - Bug fixes, typos
- `minor` - New features (backwards compatible)
- `major` - Breaking changes

### Package Management
```bash
brew install <formula>            # CLI tool
brew install --cask <app>         # GUI app
pip install <package>             # Python
npm install -g <package>          # Node global
```

### Common Operations
```bash
# Check if tool exists
which <tool> && <tool> --version

# Reload shell config
source ~/.zshrc

# Start Docker
open -a Docker

# Run local LLM
ollama run llama2

# Create VM
vagrant init ubuntu/jammy64 && vagrant up
```

## Tool Availability Matrix

| Category | Light | Standard | Advanced |
|----------|:-----:|:--------:|:--------:|
| Homebrew, Git, VS Code | Y | Y | Y |
| Python (pyenv), Node (nvm) | Y | Y | Y |
| Chrome, Firefox | Y | Y | Y |
| VirtualBox | Y | Y | Y |
| Docker, kubectl, Terraform | - | Y | Y |
| Vagrant, Packer, Multipass | - | Y | Y |
| PostgreSQL, Redis | - | Y | Y |
| Slack, Discord, Zoom | - | Y | Y |
| Ollama, LM Studio, AI tools | - | - | Y |
| UTM, QEMU, Lima, Colima | - | - | Y |
| Wireshark, nmap, mitmproxy | - | - | Y |
| All JetBrains IDEs | - | - | Y |

## Error Resolution Patterns

### "command not found"
1. Check: `which <tool>`
2. Fix: `source ~/.zshrc`
3. If still missing: `brew install <tool>`

### "permission denied"
1. Homebrew: `sudo chown -R $(whoami) $(brew --prefix)/*`
2. npm: Use nvm (should already be configured)

### "cannot connect to Docker"
1. Start: `open -a Docker`
2. Wait 30s, verify: `docker info`

### "port already in use"
1. Find: `lsof -i :<port>`
2. Kill: `kill <PID>`

## Workflow Detection

Detect user's workflow from their questions:

| Keywords | Likely Workflow | Suggest Tools |
|----------|-----------------|---------------|
| react, vue, next, frontend | Web Development | nvm, VS Code, Chrome DevTools |
| fastapi, django, flask, express | API Development | pyenv/nvm, Postman, Docker |
| docker, kubernetes, k8s, terraform | DevOps | Docker, kubectl, Helm, Terraform |
| ollama, llm, langchain, ai | AI/ML | Ollama, Python, LangChain, ChromaDB |
| postgres, mysql, redis, sql | Data Engineering | PostgreSQL, DBeaver, pgcli |
| vm, virtual, vagrant, ubuntu | Virtualization | VirtualBox, Vagrant, UTM |
| pentest, security, scan | Security Testing | Wireshark, nmap, mitmproxy |

## Category Exclusion Guide

Map user requests to exclusion flags:

| User Says | Exclude Flag |
|-----------|--------------|
| "Don't need AI tools" | `--exclude ai` |
| "No chat apps" | `--exclude communication` |
| "Skip virtualization" | `--exclude virtualization` |
| "Just code, no extras" | `--exclude communication,apps,browsers` |
| "Backend only, no frontend" | `--exclude browsers` |
| "DevOps without AI" | `--exclude ai,communication` |
| "Minimal dev setup" | Use `light` package instead |

**Example conversation:**
```
User: "I want standard package but don't need AI or chat apps"
Agent: ./install.sh --package standard --exclude ai,communication
```

---

## Response Templates

### When user wants to start a project

```
1. Identify workflow type from keywords
2. Check if required tools are installed: `which <tool>`
3. If missing, provide install command
4. Provide project scaffold commands from use-case guide
5. Offer to explain any step
```

### When user has an error

```
1. Identify error type (not found, permission, connection)
2. Check troubleshooting.md for known fix
3. Provide specific fix command
4. Verify fix: `<tool> --version`
5. If still broken, suggest: `./tests/validate.sh`
```

### When user asks "what should I install"

```
1. Ask about their primary work (web, api, devops, ai, data)
2. Recommend package tier:
   - Just starting/minimal → light
   - Professional developer → standard
   - Power user/full stack → advanced
3. Show what's included: `./install.sh --show-packages`
```

## File Locations

| What | Where |
|------|-------|
| Main installer | `./install.sh` |
| Validation | `./tests/validate.sh` |
| State file | `~/.mac-dev-machine/installed.txt` |
| Shell config | `~/.zshrc` |
| Homebrew (Apple Silicon) | `/opt/homebrew` |
| Homebrew (Intel) | `/usr/local` |
| Logs | `./logs/` |

## Cross-Reference Index

When these topics come up, read the specific file:

- **Python setup**: `ai-agent-guide.md` → Version Managers section
- **Node setup**: `ai-agent-guide.md` → Version Managers section
- **Docker basics**: `ai-agent-guide.md` → Docker Commands section
- **Kubernetes**: `use-cases/devops.md` → Kubernetes section
- **Terraform**: `use-cases/devops.md` → Infrastructure as Code section
- **Local LLMs**: `use-cases/ai-ml.md` → Local LLM section
- **RAG apps**: `use-cases/ai-ml.md` → RAG Pipeline section
- **REST APIs**: `use-cases/api-development.md`
- **Databases**: `use-cases/data-engineering.md`
- **VMs**: `use-cases/virtualization.md`
- **Common errors**: `troubleshooting.md`

## Validation Output Actions

When user runs `./tests/validate.sh` and sees warnings:

| Warning Type | Action |
|--------------|--------|
| Formula missing | `brew install <formula>` |
| Cask missing | `brew install --cask <cask>` |
| Pip package missing | `pip install <package>` |
| Multiple missing | Run `./install.sh --package advanced` |

The validation script now shows copy-paste install commands for all missing tools.
