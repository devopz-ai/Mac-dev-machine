# Tool Combinations

Tools that work best together, organized by workflow.

## Quick Reference Matrix

| Workflow | Primary | Supporting | Optional |
|----------|---------|------------|----------|
| Python Dev | pyenv, pip | VS Code, pytest | Docker, PostgreSQL |
| Node Dev | nvm, npm | VS Code, ESLint | Docker, Redis |
| Go Dev | go | VS Code/GoLand | Docker, k8s |
| DevOps | Terraform, Docker | kubectl, Helm | Ansible, Pulumi |
| AI/ML | Ollama, Python | LangChain, ChromaDB | LM Studio, Qdrant |
| API Testing | Postman | httpie, jq | Bruno, Insomnia |
| Databases | DBeaver | pgcli/mycli | TablePlus |
| VMs | VirtualBox | Vagrant | UTM, Lima |

---

## Web Development Stack

### Frontend (React/Vue/Next.js)

```
nvm + npm/pnpm → VS Code → Chrome DevTools → Git
```

| Tool | Purpose | Command |
|------|---------|---------|
| nvm | Node version | `nvm use 20` |
| pnpm | Fast package manager | `pnpm install` |
| VS Code | Editor | `code .` |
| Chrome | Debug | F12 / DevTools |
| Prettier | Format | Auto on save |
| ESLint | Lint | Auto on save |

### Backend (Python/Node/Go)

**Python + FastAPI:**
```
pyenv → pip/poetry → VS Code → Docker → PostgreSQL
```

**Node + Express:**
```
nvm → npm → VS Code → Docker → Redis
```

**Go + Gin:**
```
go → VS Code/GoLand → Docker → PostgreSQL
```

---

## DevOps Stack

### Infrastructure as Code

```
Terraform → Docker → kubectl → Helm
    ↓
AWS/GCP/Azure CLI
```

| Task | Tools |
|------|-------|
| Provision infra | Terraform, Pulumi |
| Build images | Docker, Packer |
| Deploy containers | kubectl, Helm |
| Configure servers | Ansible |
| Monitor | k9s, Lens |

### CI/CD Pipeline

```bash
# Local testing workflow
docker build → docker-compose up → terraform plan → git push
```

---

## AI/ML Development Stack

### Local LLM Development

```
Ollama → LangChain → ChromaDB → Python
   ↓
LM Studio (GUI alternative)
```

| Component | Tool | Purpose |
|-----------|------|---------|
| LLM Runtime | Ollama | Run models locally |
| Framework | LangChain | Build LLM apps |
| Vector DB | ChromaDB/Qdrant | Store embeddings |
| UI | Streamlit | Quick prototypes |

### RAG Application Stack

```python
# Typical RAG stack
Ollama (LLM) + ChromaDB (vectors) + LangChain (orchestration)
```

Tools needed:
```bash
ollama pull llama2
pip install langchain chromadb sentence-transformers
```

### AI Image Generation

```
DiffusionBee or Draw Things → Metal acceleration → Output
```

---

## Database Development Stack

### SQL Development

```
PostgreSQL/MySQL → DBeaver/TablePlus → pgcli/mycli
```

| Task | Tool |
|------|------|
| GUI management | DBeaver (free), TablePlus (paid) |
| CLI with autocomplete | pgcli, mycli, litecli |
| Migrations | Alembic (Python), Prisma (Node) |

### NoSQL Development

```
MongoDB → MongoDB Compass → mongosh
Redis → redis-cli → RedisInsight
```

---

## API Development Stack

### REST API Testing

```
Postman/Bruno → httpie → jq → curl
```

| Task | Tool | Example |
|------|------|---------|
| GUI testing | Postman | Collections, environments |
| CLI testing | httpie | `http GET api.example.com` |
| Parse JSON | jq | `curl ... \| jq '.data'` |
| Load testing | k6, wrk | `k6 run script.js` |

### GraphQL Development

```
Postman/Insomnia → Apollo Studio → graphql-cli
```

---

## Virtualization Stack

### VM Workflows

| Use Case | Tools |
|----------|-------|
| Cross-platform testing | VirtualBox + Vagrant |
| Linux on Mac (M-series) | UTM or Lima |
| Quick Ubuntu VM | Multipass |
| Container alternative | Podman, Colima |

### Vagrant + VirtualBox

```bash
# Create VM from template
vagrant init ubuntu/jammy64
vagrant up
vagrant ssh
```

### UTM for Apple Silicon

```bash
# Best for ARM64 VMs on M1/M2/M3/M4
# Download from: https://mac.getutm.app/
# Supports: Linux ARM64, Windows ARM64
```

---

## Security Testing Stack

```
Wireshark → nmap → mitmproxy → Burp Suite
```

| Task | Tool |
|------|------|
| Packet capture | Wireshark |
| Port scanning | nmap |
| HTTP proxy | mitmproxy |
| Web security | Burp Suite (manual install) |

---

## Tool Chains by Project Type

### SaaS Web Application

```
Frontend: nvm + React + VS Code
Backend: pyenv + FastAPI + Docker
Database: PostgreSQL + Redis
DevOps: Terraform + kubectl + GitHub Actions
```

### AI Chatbot

```
LLM: Ollama + llama2/mistral
Framework: LangChain + Python
Vector DB: ChromaDB
UI: Streamlit or Gradio
```

### Mobile App with Backend

```
Mobile: React Native or Flutter (manual setup)
Backend: Node.js + Express
Database: PostgreSQL + Redis
API: REST or GraphQL
```

### Data Pipeline

```
Extract: Python + requests/scrapy
Transform: pandas + dbt
Load: PostgreSQL/BigQuery
Orchestrate: Airflow (manual) or Prefect
```

---

## Integration Patterns

### Docker + Kubernetes Dev

```bash
# Build → Test locally → Deploy to cluster
docker build -t myapp .
docker-compose up  # Local testing
kubectl apply -f k8s/  # Deploy
k9s  # Monitor
```

### Terraform + Ansible

```bash
# Provision → Configure
terraform apply  # Create infrastructure
ansible-playbook -i inventory playbook.yml  # Configure
```

### Python + Ollama + LangChain

```python
from langchain_community.llms import Ollama
from langchain.chains import LLMChain

llm = Ollama(model="llama2")
chain = LLMChain(llm=llm, prompt=prompt)
result = chain.run(input="Hello")
```
