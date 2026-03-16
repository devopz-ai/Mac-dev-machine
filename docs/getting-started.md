# Getting Started

First steps after running Mac Dev Machine setup.

## Post-Install Checklist

```bash
# 1. Reload shell configuration
source ~/.zshrc

# 2. Verify core tools
brew --version && echo "✓ Homebrew"
python --version && echo "✓ Python"
node --version && echo "✓ Node.js"
git --version && echo "✓ Git"

# 3. Configure Git identity
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## Essential First Steps

### 1. Terminal Setup

| Task | Command |
|------|---------|
| Open iTerm2 | `Cmd+Space` → "iTerm" |
| Set as default | iTerm2 → Make iTerm2 Default Term |
| Import profile | Preferences → Profiles → Import |

### 2. VS Code Extensions

```bash
# Install essential extensions
code --install-extension ms-python.python
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension eamodio.gitlens
```

### 3. Language Runtimes

**Python:**
```bash
pyenv install 3.12
pyenv global 3.12
python -m pip install --upgrade pip
```

**Node.js:**
```bash
nvm install --lts
nvm alias default lts/*
npm install -g typescript
```

**Go:**
```bash
# Already configured, verify:
go version
echo $GOPATH  # Should be ~/go
```

**Rust:**
```bash
rustup update
rustc --version
```

### 4. Docker Setup

```bash
# Start Docker Desktop (GUI)
open -a Docker

# Wait for daemon, then verify
docker run hello-world
```

### 5. Cloud CLI Login

```bash
# AWS
aws configure
# → Enter: Access Key, Secret Key, Region, Output format

# GCP
gcloud auth login
gcloud config set project <project-id>

# Azure
az login
```

## Quick Verification

```bash
# Run validation script
./tests/validate.sh --quick

# Or manual checks
which python node go docker kubectl terraform
```

## Directory Structure Recommendations

```
~/
├── Projects/           # All code projects
│   ├── personal/
│   ├── work/
│   └── learning/
├── .config/            # Tool configurations
├── .ssh/               # SSH keys
└── go/                 # Go workspace (GOPATH)
```

Create the structure:
```bash
mkdir -p ~/Projects/{personal,work,learning}
```

## Next Steps

| Goal | Guide |
|------|-------|
| Build a web app | [Web Development](use-cases/web-development.md) |
| Set up CI/CD | [DevOps](use-cases/devops.md) |
| Run local AI | [AI/ML Development](use-cases/ai-ml.md) |
| Test APIs | [API Development](use-cases/api-development.md) |

## Getting Help

```bash
# Tool-specific help
<tool> --help
man <tool>
tldr <tool>  # Simplified examples

# This project
./install.sh --help
./uninstall.sh --help
```

## Common First Issues

| Issue | Solution |
|-------|----------|
| "command not found" | `source ~/.zshrc` |
| Wrong Python version | `pyenv global 3.12` |
| Docker not running | Open Docker Desktop app |
| Permission denied | `sudo chown -R $(whoami) $(brew --prefix)/*` |
