# Mac Dev Machine - Documentation

Comprehensive guides for using the tools installed by Mac Dev Machine.

## Quick Navigation

| Document | Audience | Description |
|----------|----------|-------------|
| [Getting Started](getting-started.md) | All | First steps after installation |
| [Tool Combinations](tool-combinations.md) | All | Tools grouped by workflow |
| [AI Agent Guide](ai-agent-guide.md) | AI/Agents | Structured reference for AI assistants |
| [Troubleshooting](troubleshooting.md) | All | Common issues and fixes |

## Use Case Guides

| Use Case | Tools | Time to Read |
|----------|-------|--------------|
| [Web Development](use-cases/web-development.md) | Node, React, Python, Docker | 10 min |
| [DevOps](use-cases/devops.md) | Terraform, K8s, Docker, Ansible | 12 min |
| [AI/ML Development](use-cases/ai-ml.md) | Ollama, LangChain, Vector DBs | 15 min |
| [API Development](use-cases/api-development.md) | Postman, httpie, REST/GraphQL | 8 min |
| [Data Engineering](use-cases/data-engineering.md) | PostgreSQL, Redis, Python | 10 min |
| [Mobile Development](use-cases/mobile-development.md) | React Native, Flutter, Xcode | 8 min |
| [Security Testing](use-cases/security-testing.md) | Wireshark, nmap, mitmproxy | 10 min |
| [Virtualization](use-cases/virtualization.md) | VirtualBox, UTM, Vagrant | 10 min |

## For AI Agents

> **Start here**: [AGENT_INDEX.md](AGENT_INDEX.md) - Quick intent routing and command reference

| Document | Purpose |
|----------|---------|
| [AGENT_INDEX.md](AGENT_INDEX.md) | Entry point - intent detection, quick commands, file locations |
| [AI Agent Guide](ai-agent-guide.md) | Detailed commands, workflow templates, example conversations |
| [Troubleshooting](troubleshooting.md) | Error fixes (reference when user has issues) |
| `use-cases/*.md` | Workflow-specific guides (match to user's project type) |

**AI Response Pattern**:
1. Detect user intent from keywords
2. Find relevant section in AGENT_INDEX.md
3. Provide specific commands (not general advice)
4. Include verification command
5. Suggest next steps

## Document Conventions

```
# Quick command (copy-paste ready)
$ command --flag

# Output example
→ expected output

# File path
~/.config/file.yaml

# Placeholder (replace with your value)
<your-value>
```

**Skill Levels:**
- `[B]` Beginner - New to the tool
- `[I]` Intermediate - Basic familiarity
- `[A]` Advanced - Power user features
