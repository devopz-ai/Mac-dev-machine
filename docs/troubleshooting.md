# Troubleshooting Guide

Common issues and solutions for Mac Dev Machine tools.

## Quick Fixes

| Symptom | Quick Fix |
|---------|-----------|
| Command not found | `source ~/.zshrc` |
| Wrong Python version | `pyenv global 3.12` |
| Wrong Node version | `nvm use 20` |
| Docker not running | `open -a Docker` |
| Permission denied | `sudo chown -R $(whoami) $(brew --prefix)/*` |
| Port already in use | `lsof -i :<port>` then `kill <PID>` |

---

## Homebrew Issues

### "Command not found: brew"

```bash
# Apple Silicon (M1/M2/M3/M4)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel Mac
eval "$(/usr/local/bin/brew shellenv)"

# Add to ~/.zshrc permanently
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### Permission Errors

```bash
# Fix ownership
sudo chown -R $(whoami) $(brew --prefix)/*

# Fix permissions
chmod -R u+w $(brew --prefix)/*
```

### Brew Update Fails

```bash
# Reset Homebrew
cd $(brew --prefix)/Homebrew
git fetch origin
git reset --hard origin/master

# Clear cache
rm -rf $(brew --cache)
brew cleanup
```

---

## Python Issues

### "Command not found: python"

```bash
# Check pyenv is loaded
which pyenv

# If not found, add to ~/.zshrc:
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

source ~/.zshrc
```

### Wrong Python Version

```bash
# Check versions
pyenv versions
python --version

# Set global version
pyenv global 3.12

# Set local (project) version
pyenv local 3.11

# Verify
python --version
```

### pip Install Fails

```bash
# Upgrade pip
python -m pip install --upgrade pip

# Install with user flag
pip install --user package_name

# Clear cache
pip cache purge
```

### Virtual Environment Issues

```bash
# Create fresh venv
rm -rf .venv
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## Node.js Issues

### "Command not found: node"

```bash
# Check nvm is loaded
which nvm

# If not found, add to ~/.zshrc:
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

source ~/.zshrc
```

### Wrong Node Version

```bash
# List installed versions
nvm ls

# Install and use specific version
nvm install 20
nvm use 20
nvm alias default 20
```

### npm Permission Errors

```bash
# Should not happen with nvm, but if it does:
sudo chown -R $(whoami) ~/.npm
```

### node_modules Issues

```bash
# Clean reinstall
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

---

## Docker Issues

### Docker Daemon Not Running

```bash
# Start Docker Desktop
open -a Docker

# Wait for startup, then verify
docker info
```

### Cannot Connect to Docker

```bash
# Check Docker is running
docker info

# If error, restart Docker Desktop
osascript -e 'quit app "Docker"'
open -a Docker
```

### Port Already in Use

```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>

# Or stop container using port
docker ps
docker stop <container_id>
```

### Out of Disk Space

```bash
# Clean unused data
docker system prune -a

# Remove all volumes (careful!)
docker volume prune

# Check disk usage
docker system df
```

---

## Git Issues

### "Please tell me who you are"

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### SSH Authentication Failed

```bash
# Check SSH key exists
ls -la ~/.ssh/id_*

# Generate new key
ssh-keygen -t ed25519 -C "your@email.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to GitHub
cat ~/.ssh/id_ed25519.pub
# Add to GitHub → Settings → SSH keys
```

### SSL Certificate Error

```bash
# Temporary bypass (not recommended)
git config --global http.sslVerify false

# Better: Update certificates
brew install ca-certificates
```

---

## Kubernetes Issues

### kubectl Connection Refused

```bash
# Check context
kubectl config current-context

# List contexts
kubectl config get-contexts

# Switch context
kubectl config use-context docker-desktop

# For Minikube
minikube start
kubectl config use-context minikube
```

### Minikube Won't Start

```bash
# Delete and recreate
minikube delete
minikube start

# With specific driver
minikube start --driver=docker
```

---

## Database Issues

### PostgreSQL Connection Refused

```bash
# Check service status
brew services list

# Start service
brew services start postgresql@16

# Check if running
pg_isready
```

### Redis Connection Refused

```bash
# Start Redis
brew services start redis

# Verify
redis-cli ping
# Should return: PONG
```

---

## VS Code Issues

### Extensions Not Working

```bash
# Reload window
Cmd+Shift+P → "Reload Window"

# Reinstall extension
code --uninstall-extension <extension-id>
code --install-extension <extension-id>
```

### Terminal Integration Issues

```bash
# Reset shell integration
Cmd+Shift+P → "Terminal: Reset"

# Set default shell
Cmd+Shift+P → "Terminal: Select Default Profile"
```

---

## General Diagnostics

### Check Tool Installation

```bash
# Verify tool is installed
which <tool>
command -v <tool>
<tool> --version
```

### Check PATH

```bash
# Print PATH
echo $PATH | tr ':' '\n'

# Check if directory is in PATH
echo $PATH | grep -q "/path/to/check" && echo "Found" || echo "Not found"
```

### Check Environment Variables

```bash
# List all
env

# Check specific
echo $VARIABLE_NAME
```

### Check Running Services

```bash
# Homebrew services
brew services list

# All processes on port
lsof -i :<port>

# Specific process
ps aux | grep <process>
```

### Reset Shell Configuration

```bash
# Backup current
cp ~/.zshrc ~/.zshrc.backup

# Reload
source ~/.zshrc

# Or restart terminal
```

---

## Getting More Help

```bash
# Tool-specific help
<tool> --help
man <tool>

# Simplified examples
tldr <tool>

# Search issues
brew info <formula>
```

## Reinstall Tools

```bash
# Reinstall Homebrew formula
brew reinstall <formula>

# Reinstall cask
brew reinstall --cask <app>

# Complete reinstall
brew uninstall <formula>
brew install <formula>
```
