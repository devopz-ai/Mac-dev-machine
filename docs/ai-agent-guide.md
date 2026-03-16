# AI Agent Guide

Structured reference for AI assistants (Claude, GPT, Copilot, etc.) helping developers use Mac Dev Machine tools.

## Quick Decision Trees

### "I want to build..."

```
Web App?
├── Frontend only → nvm + VS Code + Chrome
├── Full stack → nvm + pyenv + Docker + PostgreSQL
└── API only → pyenv + FastAPI + Postman

Mobile App?
├── React Native → nvm + Xcode + Android Studio*
├── Flutter → Flutter SDK* + VS Code
└── Native iOS → Xcode* + Swift

AI/ML App?
├── Local LLM → Ollama + Python + LangChain
├── Cloud LLM → Python + openai/anthropic SDK
└── Image Gen → DiffusionBee or Draw Things

DevOps?
├── Containers → Docker + kubectl + Helm
├── IaC → Terraform + AWS/GCP/Azure CLI
└── VMs → VirtualBox + Vagrant

* = requires manual installation
```

### "How do I..."

| Task | Command |
|------|---------|
| Install Python package | `pip install <pkg>` |
| Install Node package | `npm install <pkg>` |
| Install system tool | `brew install <pkg>` |
| Install GUI app | `brew install --cask <app>` |
| Run local LLM | `ollama run llama2` |
| Start Docker | `open -a Docker` |
| Create VM | `vagrant init && vagrant up` |
| Test API | `http GET <url>` |
| Parse JSON | `echo '<json>' \| jq '.'` |

---

## Command Reference by Category

### Package Management

```bash
# Homebrew (system packages)
brew install <formula>        # CLI tools
brew install --cask <app>     # GUI apps
brew update && brew upgrade   # Update all
brew list                     # Show installed
brew search <term>            # Find packages

# Python (pip)
pip install <package>
pip install -r requirements.txt
pip list
pip freeze > requirements.txt

# Node (npm/pnpm)
npm install <package>         # Project local
npm install -g <package>      # Global
pnpm install                  # Faster alternative
```

### Version Managers

```bash
# Python (pyenv)
pyenv install --list          # Available versions
pyenv install 3.12            # Install version
pyenv global 3.12             # Set default
pyenv local 3.11              # Project-specific
python --version              # Verify

# Node (nvm)
nvm ls-remote                 # Available versions
nvm install 20                # Install version
nvm use 20                    # Switch version
nvm alias default 20          # Set default
node --version                # Verify

# Ruby (rbenv)
rbenv install -l              # Available versions
rbenv install 3.3.0           # Install version
rbenv global 3.3.0            # Set default
```

### Docker Commands

```bash
# Images
docker build -t <name> .      # Build from Dockerfile
docker pull <image>           # Download image
docker images                 # List images

# Containers
docker run -it <image>        # Interactive
docker run -d -p 8080:80 <img> # Detached with port
docker ps                     # Running containers
docker ps -a                  # All containers
docker stop <id>              # Stop container
docker rm <id>                # Remove container

# Compose
docker-compose up             # Start services
docker-compose up -d          # Detached
docker-compose down           # Stop services
docker-compose logs -f        # Follow logs
```

### Kubernetes Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes

# Workloads
kubectl get pods
kubectl get deployments
kubectl get services

# Apply/Delete
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>

# Debugging
kubectl logs <pod>
kubectl exec -it <pod> -- /bin/bash
kubectl describe pod <pod>

# Context switching
kubectx                       # List contexts
kubectx <context>             # Switch context
k9s                           # TUI dashboard
```

### Terraform Commands

```bash
terraform init                # Initialize
terraform plan                # Preview changes
terraform apply               # Apply changes
terraform destroy             # Destroy infra
terraform fmt                 # Format files
terraform validate            # Validate config
```

### Git Commands

```bash
# Basics
git status
git add .
git commit -m "message"
git push

# Branching
git checkout -b <branch>
git merge <branch>
git rebase <branch>

# GitHub CLI
gh repo create
gh pr create
gh pr list
gh issue list
```

### AI/ML Commands

```bash
# Ollama
ollama list                   # Installed models
ollama pull <model>           # Download model
ollama run <model>            # Interactive chat
ollama serve                  # Start server (API)

# Models to suggest:
# - llama2 (general purpose)
# - codellama (coding)
# - mistral (fast, good quality)
# - mixtral (larger, better quality)

# LM Studio
# GUI app - open from Applications
# API compatible with OpenAI format at localhost:1234
```

---

## Workflow Templates

### Start New Python Project

```bash
mkdir myproject && cd myproject
pyenv local 3.12
python -m venv .venv
source .venv/bin/activate
pip install <dependencies>
echo ".venv/" >> .gitignore
git init
```

### Start New Node Project

```bash
mkdir myproject && cd myproject
nvm use 20
npm init -y
npm install <dependencies>
echo "node_modules/" >> .gitignore
git init
```

### Start Docker Project

```bash
# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "main.py"]
EOF

# Build and run
docker build -t myapp .
docker run -p 8000:8000 myapp
```

### Start Terraform Project

```bash
mkdir infra && cd infra
cat > main.tf << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
EOF

terraform init
```

### Start Local AI Project

```bash
# 1. Pull model
ollama pull llama2

# 2. Create Python project
mkdir ai-project && cd ai-project
python -m venv .venv
source .venv/bin/activate
pip install langchain langchain-community chromadb

# 3. Test connection
python -c "from langchain_community.llms import Ollama; print(Ollama(model='llama2').invoke('Hello'))"
```

---

## Error Handling

### Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `command not found: brew` | Shell not configured | `eval "$(/opt/homebrew/bin/brew shellenv)"` |
| `command not found: python` | pyenv not loaded | `source ~/.zshrc` |
| `command not found: node` | nvm not loaded | `source ~/.zshrc` |
| `Cannot connect to Docker` | Docker not running | `open -a Docker` |
| `EACCES permission denied` | npm global permission | Use nvm (already configured) |
| `SSL certificate error` | Proxy/firewall | Check network settings |
| `Port already in use` | Another process | `lsof -i :<port>` then kill |

### Debug Commands

```bash
# Check if tool is installed
which <tool>
command -v <tool>

# Check version
<tool> --version

# Check PATH
echo $PATH | tr ':' '\n'

# Check environment variable
echo $VARIABLE_NAME
env | grep VARIABLE

# Check what's using a port
lsof -i :8080
```

---

## Suggested Prompts for Users

When user is stuck, suggest these prompts:

**For setup issues:**
> "Check if [tool] is installed and show me the version"

**For project start:**
> "Help me create a new [Python/Node/Go] project with [framework]"

**For debugging:**
> "This command gives error: [error]. How do I fix it?"

**For learning:**
> "Explain what [tool] does and show me basic usage"

---

## Tool Availability by Package

| Tool | Light | Standard | Advanced |
|------|:-----:|:--------:|:--------:|
| Homebrew | ✓ | ✓ | ✓ |
| Python/pyenv | ✓ | ✓ | ✓ |
| Node/nvm | ✓ | ✓ | ✓ |
| VS Code | ✓ | ✓ | ✓ |
| Docker | - | ✓ | ✓ |
| kubectl | - | ✓ | ✓ |
| Terraform | - | ✓ | ✓ |
| Ollama | - | - | ✓ |
| LM Studio | - | - | ✓ |
| Wireshark | - | - | ✓ |
| VirtualBox | ✓ | ✓ | ✓ |
| Vagrant | - | ✓ | ✓ |
| UTM | - | - | ✓ |

---

## Response Patterns

### When user asks "How do I install X?"

1. Check if it's in the package list
2. If yes: `brew install X` or `brew install --cask X`
3. If no: Provide manual installation steps
4. Verify: `X --version` or `which X`

### When user asks "How do I use X with Y?"

1. Check [Tool Combinations](tool-combinations.md)
2. Provide minimal working example
3. Link to relevant use-case guide

### When user gets an error

1. Identify error type (permission, not found, connection)
2. Check common fixes table above
3. Provide specific fix command
4. Verify fix worked

---

## Example Agent Conversations

### Example 1: User wants to build an AI app

**User**: "I want to build a chatbot using local LLMs"

**Agent Response**:
```
Great! Here's what you need:

1. Check if Ollama is installed:
   which ollama

2. If not installed:
   brew install ollama

3. Pull a model:
   ollama pull llama2

4. Create your Python project:
   mkdir chatbot && cd chatbot
   python -m venv .venv
   source .venv/bin/activate
   pip install langchain langchain-community

5. Test the connection:
   python -c "from langchain_community.llms import Ollama; print(Ollama(model='llama2').invoke('Hello'))"

See docs/use-cases/ai-ml.md for full RAG pipeline setup.
```

### Example 2: User has an error

**User**: "I get 'command not found: node' when I try to run npm"

**Agent Response**:
```
Node.js isn't loaded in your shell. Fix:

1. Reload your shell config:
   source ~/.zshrc

2. Check if nvm is working:
   nvm --version

3. If nvm works, install/use Node:
   nvm install 20
   nvm use 20

4. Verify:
   node --version
   npm --version

If nvm itself isn't found, add this to ~/.zshrc:
   export NVM_DIR="$HOME/.nvm"
   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### Example 3: User wants to know what to install

**User**: "I'm a backend developer working with Python APIs and Docker. What package should I choose?"

**Agent Response**:
```
For Python backend + Docker work, I recommend the **standard** package.

It includes everything you need:
- Python with pyenv (version management)
- Docker + docker-compose
- kubectl + Helm (if you deploy to K8s)
- PostgreSQL + Redis
- VS Code + PyCharm CE
- Postman for API testing

Install with:
   ./install.sh --package standard

If you also want AI tools (Ollama, LangChain) or advanced networking (Wireshark),
go with **advanced** instead:
   ./install.sh --package advanced

Preview what's included:
   ./install.sh --show-packages
```

### Example 4: User ran validation and has warnings

**User**: Shows validation output with 15 warnings

**Agent Response**:
```
Your essential tools are all working (0 failures).

The 21 warnings are optional tools you haven't installed. The validation
script shows exactly how to install them:

For CLI tools:
   brew install colima lima packer vagrant pulumi

For GUI apps:
   brew install --cask virtualbox utm multipass

Or if you want everything, run:
   ./install.sh --package advanced

You can also pick specific tools you actually need - not everything
is required for every workflow.
```

---

## Context-Aware Help

### Detect User's Environment

Before giving commands, understand their setup:

```bash
# Check architecture (commands may differ)
uname -m
# arm64 = Apple Silicon (M1/M2/M3/M4)
# x86_64 = Intel

# Check what's installed
./tests/validate.sh --quick

# Check current Python
python --version
which python

# Check current Node
node --version
which node
```

### Adjust Commands for Architecture

| Tool | Apple Silicon | Intel |
|------|---------------|-------|
| Homebrew path | `/opt/homebrew` | `/usr/local` |
| VMs | UTM (native ARM) | VirtualBox |
| Docker | Docker Desktop or Colima | Docker Desktop |
| QEMU | `qemu-system-aarch64` | `qemu-system-x86_64` |

### Project Type Detection

Identify project type from files in directory:

| File Present | Project Type | Suggest Tools |
|--------------|--------------|---------------|
| `package.json` | Node.js | nvm, npm/pnpm |
| `requirements.txt` | Python | pyenv, pip, venv |
| `Cargo.toml` | Rust | rustup, cargo |
| `go.mod` | Go | go |
| `Dockerfile` | Container | Docker, docker-compose |
| `*.tf` | Terraform | terraform |
| `Vagrantfile` | VM | VirtualBox, Vagrant |
| `docker-compose.yml` | Multi-container | Docker Compose |
