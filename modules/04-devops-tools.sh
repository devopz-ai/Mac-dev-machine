#!/bin/bash
#
# Module 04: DevOps Tools
# Installs Docker, Kubernetes, Terraform, cloud CLIs
#

set -e

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing DevOps tools..."

# Install Docker
install_docker() {
    log_step "Installing Docker..."

    install_cask "docker" "Docker Desktop"

    # Docker CLI tools
    install_formula "docker-compose" "Docker Compose"
    install_formula "docker-credential-helper" "Docker Credential Helper"

    log_info "Note: Open Docker Desktop to complete setup"
    log_success "Docker setup completed"
}

# Install Kubernetes tools
install_kubernetes() {
    log_step "Installing Kubernetes tools..."

    # kubectl
    install_formula "kubernetes-cli" "kubectl"

    # k9s - Kubernetes TUI
    install_formula "k9s" "k9s"

    # Helm
    install_formula "helm" "Helm"

    # kustomize
    install_formula "kustomize" "Kustomize"

    # kubectx/kubens
    install_formula "kubectx" "kubectx/kubens"

    # stern - multi-pod log tailing
    install_formula "stern" "stern"

    # Local Kubernetes
    install_formula "minikube" "Minikube"
    install_formula "kind" "kind"

    # Configure kubectl completion
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# Kubernetes"
    append_if_missing "$shell_config" 'alias k="kubectl"'
    append_if_missing "$shell_config" 'source <(kubectl completion zsh)'

    log_success "Kubernetes tools completed"
}

# Install Terraform
install_terraform() {
    log_step "Installing Terraform..."

    install_formula "terraform" "Terraform"
    install_formula "terragrunt" "Terragrunt"
    install_formula "tflint" "TFLint"
    install_formula "terraform-docs" "terraform-docs"

    # tfenv for version management
    install_formula "tfenv" "tfenv"

    log_success "Terraform setup completed"
}

# Install Ansible
install_ansible() {
    log_step "Installing Ansible..."

    install_formula "ansible" "Ansible"
    install_formula "ansible-lint" "Ansible Lint"

    log_success "Ansible setup completed"
}

# Install AWS CLI and tools
install_aws() {
    log_step "Installing AWS tools..."

    install_formula "awscli" "AWS CLI"
    install_formula "aws-sam-cli" "AWS SAM CLI"
    install_formula "aws-cdk" "AWS CDK"

    # AWS session manager plugin
    install_cask "session-manager-plugin" "AWS Session Manager" || true

    # Configure AWS completion
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# AWS"
    append_if_missing "$shell_config" 'complete -C aws_completer aws'

    log_success "AWS tools completed"
}

# Install Azure CLI
install_azure() {
    log_step "Installing Azure tools..."

    install_formula "azure-cli" "Azure CLI"

    log_success "Azure tools completed"
}

# Install Google Cloud SDK
install_gcloud() {
    log_step "Installing Google Cloud tools..."

    install_cask "google-cloud-sdk" "Google Cloud SDK"

    # Configure gcloud in shell
    local shell_config="$HOME/.zshrc"
    local gcloud_path="$(brew --prefix)/share/google-cloud-sdk"

    if [[ -d "$gcloud_path" ]]; then
        append_if_missing "$shell_config" ""
        append_if_missing "$shell_config" "# Google Cloud SDK"
        append_if_missing "$shell_config" "source \"$gcloud_path/path.zsh.inc\""
        append_if_missing "$shell_config" "source \"$gcloud_path/completion.zsh.inc\""
    fi

    log_success "Google Cloud tools completed"
}

# Install Vault and secrets management
install_secrets_tools() {
    log_step "Installing secrets management tools..."

    install_formula "vault" "HashiCorp Vault"
    install_formula "sops" "SOPS"
    install_formula "age" "age (encryption)"

    log_success "Secrets tools completed"
}

# Install monitoring and observability tools
install_observability() {
    log_step "Installing observability tools..."

    # Prometheus
    install_formula "prometheus" "Prometheus"

    # Grafana
    install_formula "grafana" "Grafana"

    log_success "Observability tools completed"
}

# Install container tools
install_container_tools() {
    log_step "Installing container tools..."

    # Podman (Docker alternative)
    install_formula "podman" "Podman"

    # Buildah
    install_formula "buildah" "Buildah"

    # Skopeo
    install_formula "skopeo" "Skopeo"

    # Dive (container image analyzer)
    install_formula "dive" "Dive"

    # Trivy (vulnerability scanner)
    install_formula "trivy" "Trivy"

    log_success "Container tools completed"
}

# Main
main() {
    install_docker
    install_kubernetes
    install_terraform
    install_ansible
    install_aws
    install_azure
    install_gcloud
    install_secrets_tools
    install_observability
    install_container_tools

    log_success "DevOps tools completed"
}

main "$@"
