#!/bin/bash
#
# Module 10: Databases
# Installs database servers, clients, and GUI tools
#

set +e  # Continue on errors

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing database tools..."

# Install PostgreSQL
install_postgresql() {
    log_step "Installing PostgreSQL..."
    install_formula "postgresql@16" "PostgreSQL 16"
    brew link postgresql@16 --force 2>/dev/null || true
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# PostgreSQL"
    append_if_missing "$shell_config" 'export PATH="$(brew --prefix postgresql@16)/bin:$PATH"'
    log_success "PostgreSQL completed"
}

# Install MySQL
install_mysql() {
    log_step "Installing MySQL..."
    install_formula "mysql" "MySQL"
    log_success "MySQL completed"
}

# Install Redis
install_redis() {
    log_step "Installing Redis..."
    install_formula "redis" "Redis"
    log_success "Redis completed"
}

# Install MongoDB
install_mongodb() {
    log_step "Installing MongoDB..."
    brew tap mongodb/brew 2>/dev/null || true
    install_formula "mongodb-community" "MongoDB Community"
    log_success "MongoDB completed"
}

# Install SQLite
install_sqlite() {
    log_step "Installing SQLite..."
    install_formula "sqlite" "SQLite"
    log_success "SQLite completed"
}

# Install database GUI clients
install_db_guis() {
    log_step "Installing database GUI clients..."
    install_cask "dbeaver-community" "DBeaver Community"
    install_cask "tableplus" "TablePlus"
    install_cask "mongodb-compass" "MongoDB Compass"
    install_cask "pgadmin4" "pgAdmin 4" || true
    log_success "Database GUIs completed"
}

# Install database CLI tools
install_db_clis() {
    log_step "Installing database CLI tools..."
    install_pip "mycli" "mycli"
    install_pip "pgcli" "pgcli"
    install_pip "litecli" "litecli"
    log_success "Database CLIs completed"
}

# Main
main() {
    install_postgresql
    install_mysql
    install_redis
    install_mongodb
    install_sqlite
    install_db_guis
    install_db_clis
    log_success "Database tools completed"
}

main "$@"
