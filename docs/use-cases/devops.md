# DevOps & Infrastructure Guide

Tools and workflows for infrastructure automation, containerization, and deployment.

## Tool Stack

| Category | Tools |
|----------|-------|
| Containers | Docker, Podman, Docker Compose |
| Orchestration | Kubernetes, kubectl, Helm, k9s |
| IaC | Terraform, Pulumi, Ansible |
| CI/CD | GitHub Actions, GitLab CI |
| Cloud CLIs | aws, gcloud, az |
| Images | Packer |

---

## Docker Workflows

### Build & Run

```bash
# Build image
docker build -t myapp:latest .

# Run container
docker run -d -p 8080:80 --name myapp myapp:latest

# View logs
docker logs -f myapp

# Shell access
docker exec -it myapp /bin/sh

# Stop & remove
docker stop myapp && docker rm myapp
```

### Multi-Stage Dockerfile

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:80"
    environment:
      - NODE_ENV=production
    depends_on:
      - redis
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  redis_data:
```

```bash
docker-compose up -d      # Start
docker-compose ps         # Status
docker-compose logs -f    # Logs
docker-compose down -v    # Stop + remove volumes
```

---

## Kubernetes Workflows

### Local Cluster Setup

```bash
# Option 1: Minikube
minikube start
minikube dashboard

# Option 2: Kind (Kubernetes in Docker)
kind create cluster --name dev

# Option 3: Docker Desktop
# Enable Kubernetes in Docker Desktop settings
```

### Basic kubectl Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes

# Deployments
kubectl create deployment nginx --image=nginx
kubectl get deployments
kubectl scale deployment nginx --replicas=3

# Services
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get services

# Pods
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/sh

# Apply manifests
kubectl apply -f deployment.yaml
kubectl delete -f deployment.yaml
```

### Helm Charts

```bash
# Add repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search
helm search repo nginx

# Install
helm install my-nginx bitnami/nginx

# List releases
helm list

# Upgrade
helm upgrade my-nginx bitnami/nginx --set replicaCount=3

# Uninstall
helm uninstall my-nginx
```

### k9s (TUI Dashboard)

```bash
k9s                    # Launch
# Navigation:
# :pods      - View pods
# :deploy    - View deployments
# :svc       - View services
# :ns        - View namespaces
# /          - Filter
# d          - Describe
# l          - Logs
# s          - Shell
# ctrl+d     - Delete
# :q         - Quit
```

---

## Terraform Workflows

### Project Structure

```
infra/
├── main.tf           # Main config
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── terraform.tfvars  # Variable values (gitignore!)
└── modules/
    └── vpc/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Basic AWS Example

```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name = "WebServer"
  }
}

# variables.tf
variable "region" {
  default = "us-east-1"
}

# outputs.tf
output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

### Commands

```bash
terraform init          # Initialize
terraform fmt           # Format
terraform validate      # Validate
terraform plan          # Preview
terraform apply         # Apply
terraform destroy       # Destroy
terraform state list    # List resources
terraform output        # Show outputs
```

---

## Ansible Workflows

### Inventory

```ini
# inventory.ini
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### Playbook

```yaml
# playbook.yml
---
- hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
```

### Commands

```bash
# Ping hosts
ansible all -i inventory.ini -m ping

# Run playbook
ansible-playbook -i inventory.ini playbook.yml

# Check mode (dry run)
ansible-playbook -i inventory.ini playbook.yml --check

# Specific tags
ansible-playbook playbook.yml --tags "nginx"
```

---

## Cloud CLI Quick Reference

### AWS CLI

```bash
# Configure
aws configure

# EC2
aws ec2 describe-instances
aws ec2 start-instances --instance-ids i-xxx
aws ec2 stop-instances --instance-ids i-xxx

# S3
aws s3 ls
aws s3 cp file.txt s3://bucket/
aws s3 sync ./folder s3://bucket/folder

# EKS
aws eks update-kubeconfig --name cluster-name
```

### Google Cloud

```bash
# Auth
gcloud auth login
gcloud config set project PROJECT_ID

# Compute
gcloud compute instances list
gcloud compute ssh instance-name

# GKE
gcloud container clusters get-credentials cluster-name
```

### Azure CLI

```bash
# Login
az login

# VMs
az vm list
az vm start --name vm-name --resource-group rg

# AKS
az aks get-credentials --name cluster --resource-group rg
```

---

## Packer (Machine Images)

```hcl
# aws-image.pkr.hcl
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "my-ami-{{timestamp}}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }
}
```

```bash
packer init .
packer validate .
packer build .
```

---

## CI/CD Patterns

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t myapp .

      - name: Push to registry
        run: |
          echo ${{ secrets.REGISTRY_PASSWORD }} | docker login -u ${{ secrets.REGISTRY_USER }} --password-stdin
          docker push myapp

      - name: Deploy to Kubernetes
        run: kubectl apply -f k8s/
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| kubectl connection refused | Check cluster is running, kubeconfig correct |
| Terraform state lock | `terraform force-unlock <lock-id>` |
| Docker build fails | Check Dockerfile, ensure base image exists |
| Ansible SSH fails | Check SSH key permissions (600) |
| Helm chart not found | `helm repo update` |
