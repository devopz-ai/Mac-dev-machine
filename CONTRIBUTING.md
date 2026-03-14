# Contributing to Mac Dev Machine

First off, thank you for considering contributing to Mac Dev Machine! It's people like you that make this tool better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting New Tools](#suggesting-new-tools)
  - [Adding New Tools](#adding-new-tools)
  - [Improving Documentation](#improving-documentation)
  - [Submitting Pull Requests](#submitting-pull-requests)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Style Guidelines](#style-guidelines)
- [Testing Your Changes](#testing-your-changes)

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## How Can I Contribute?

### Reporting Bugs

Found a bug? Please open an issue with:

1. **Clear title** describing the problem
2. **macOS version** (`sw_vers`)
3. **Architecture** (Intel or Apple Silicon)
4. **Steps to reproduce** the issue
5. **Expected behavior** vs **actual behavior**
6. **Error logs** from `logs/install-*.log` if applicable

Use the [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md).

### Suggesting New Tools

Have a tool you'd like to see included? Open an issue with:

1. **Tool name** and official website
2. **What it does** (brief description)
3. **Why it's useful** for developers/DevOps
4. **Installation method** (brew formula, cask, pip, npm, etc.)
5. **Which package tier** it should belong to (light/standard/advanced)

Use the [Tool Request Template](.github/ISSUE_TEMPLATE/tool_request.md).

### Adding New Tools

Want to add a tool yourself? Here's how:

#### Step 1: Determine the Right Module

| Module | Tools Type |
|--------|-----------|
| `02-dev-tools.sh` | Editors, terminals, Git tools |
| `03-languages.sh` | Programming languages, runtimes |
| `04-devops-tools.sh` | Docker, K8s, cloud CLIs, IaC |
| `05-cli-tools.sh` | Command-line utilities |
| `06-network-tools.sh` | Network diagnostics, security |
| `07-communication.sh` | Chat, video, email apps |
| `08-ai-tools.sh` | AI/ML tools, LLMs |
| `09-browsers.sh` | Web browsers, automation |
| `10-databases.sh` | Databases, GUI clients |
| `11-optional-apps.sh` | Productivity, utilities |

#### Step 2: Add to the Module

```bash
# For Homebrew formula
install_formula "tool-name" "Display Name"

# For Homebrew cask (GUI apps)
install_cask "tool-name" "Display Name"

# For pip package
install_pip "package-name" "Display Name"

# For npm package
install_npm_global "package-name" "Display Name"
```

#### Step 3: Add to Package Configuration

Edit `config/packages.yaml` and add your tool to the appropriate tier:

```yaml
light:
  includes:
    cli_tools:
      - your-tool    # Only if essential

standard:
  includes:
    cli_tools:
      - your-tool    # For most developers

advanced:
  includes:
    cli_tools:
      - your-tool    # For power users
```

#### Step 4: Add Validation (Optional)

If the tool has a version command, add to `tests/validate.sh`:

```bash
check_command "tool-name" "Tool Name" "--version"
```

#### Step 5: Update Documentation

- Update `README.md` if adding a major tool
- Add to the package contents table

### Improving Documentation

Documentation improvements are always welcome:

- Fix typos or unclear instructions
- Add more examples
- Improve beginner explanations
- Translate to other languages
- Add troubleshooting tips

### Submitting Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/add-new-tool
   ```
3. **Make your changes** following our style guidelines
4. **Test** on a clean macOS installation if possible
5. **Commit** with a clear message:
   ```bash
   git commit -m "Add: tool-name to devops module"
   ```
6. **Push** and create a Pull Request

Use the [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md).

---

## Development Setup

### Prerequisites

- macOS 12+ (Monterey or later)
- Git
- Text editor (VS Code recommended)

### Clone and Setup

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR-USERNAME/Mac-dev-machine.git
cd Mac-dev-machine

# Make scripts executable
chmod +x install.sh update.sh uninstall.sh
chmod +x modules/*.sh lib/*.sh tests/*.sh
```

### Testing Locally

```bash
# Test a specific module
source lib/utils.sh
source lib/os_check.sh
source lib/tool_check.sh
./modules/02-dev-tools.sh

# Run validation
./tests/validate.sh --verbose

# Test full installation (on a VM or test machine)
./install.sh --package light
```

---

## Project Structure

```
Mac-dev-machine/
├── install.sh              # Main entry - delegates to modules
├── update.sh               # Update functionality
├── uninstall.sh            # Uninstall functionality
│
├── lib/                    # Shared functions (source these first)
│   ├── utils.sh            # Logging, install helpers
│   ├── os_check.sh         # macOS detection
│   ├── tool_check.sh       # Verification functions
│   └── state.sh            # State tracking
│
├── modules/                # Installation modules (run in order)
│   └── XX-name.sh          # Numbered for dependency order
│
├── config/
│   ├── packages.yaml       # Package tier definitions
│   ├── user-config.yaml.example
│   └── dotfiles/           # Shell config templates
│
├── tests/
│   └── validate.sh         # Post-install checks
│
├── .github/                # GitHub templates
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
│
├── README.md               # User documentation
├── CLAUDE.md               # AI agent instructions
├── CONTRIBUTING.md         # This file
├── CODE_OF_CONDUCT.md      # Community standards
└── LICENSE                 # MIT License
```

---

## Style Guidelines

### Shell Scripts

```bash
#!/bin/bash
#
# Module XX: Description
# Brief explanation of what this module does
#

set -e  # Exit on error

# Source dependencies
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

# Use functions for organization
install_something() {
    log_step "Installing something..."

    install_formula "something" "Something"

    log_success "Something completed"
}

# Main function at the bottom
main() {
    install_something
    log_success "Module completed"
}

main "$@"
```

### Naming Conventions

- **Variables**: `UPPER_SNAKE_CASE` for constants, `lower_snake_case` for locals
- **Functions**: `lower_snake_case`, verb first (`install_`, `check_`, `configure_`)
- **Files**: lowercase with hyphens (`my-module.sh`)
- **Modules**: Numbered prefix (`01-`, `02-`) for execution order

### Commit Messages

```
Type: Brief description (max 50 chars)

Longer explanation if needed. Wrap at 72 characters.
Explain what and why, not how.

Fixes #123
```

Types:
- `Add:` New feature or tool
- `Fix:` Bug fix
- `Update:` Update existing functionality
- `Docs:` Documentation only
- `Refactor:` Code restructuring
- `Test:` Adding tests

---

## Testing Your Changes

### Before Submitting

1. **Lint your shell scripts**:
   ```bash
   brew install shellcheck
   shellcheck install.sh modules/*.sh lib/*.sh
   ```

2. **Test installation** (ideally on a VM):
   ```bash
   ./install.sh --package light --yes
   ./tests/validate.sh
   ```

3. **Test uninstall**:
   ```bash
   ./uninstall.sh --tool your-new-tool
   ```

4. **Verify documentation**:
   - README reflects your changes
   - CLAUDE.md updated if needed

### Testing Environment

We recommend testing on:
- Clean macOS VM (UTM, Parallels, VMware)
- Both Intel and Apple Silicon if possible
- Different macOS versions (Ventura, Sonoma, Sequoia)

---

## Questions?

- Open an [Issue](https://github.com/devopz-ai/Mac-dev-machine/issues) for questions
- Check existing issues first
- Be patient - maintainers are volunteers

---

## Recognition

Contributors are recognized in:
- Git commit history
- GitHub contributors page
- Release notes for significant contributions

Thank you for contributing!
