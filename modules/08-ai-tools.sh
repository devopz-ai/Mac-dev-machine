#!/bin/bash
#
# Module 08: AI & LLM Tools
# Installs AI coding assistants, LLM tools, and ML frameworks
#

set +e  # Continue on errors

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing AI & LLM tools..."

# Install local LLM runners
install_local_llms() {
    log_step "Installing local LLM runners..."
    install_formula "ollama" "Ollama"
    install_cask "lm-studio" "LM Studio"
    install_cask "gpt4all" "GPT4All"
    install_cask "jan" "Jan"
    install_cask "msty" "Msty" || true
    log_success "Local LLM runners completed"
}

# Install AI coding assistants
install_ai_coding() {
    log_step "Installing AI coding assistants..."
    if command_exists npm; then
        install_npm_global "@anthropic-ai/claude-code" "Claude Code" || true
    fi
    install_pip "aider-chat" "Aider"
    install_pip "open-interpreter" "Open Interpreter"
    install_pip "shell-gpt" "Shell GPT (sgpt)"
    if command_exists gh; then
        gh extension install github/gh-copilot 2>/dev/null || log_warning "Copilot CLI requires GitHub authentication"
    fi
    log_success "AI coding assistants completed"
}

# Install LLM frameworks
install_llm_frameworks() {
    log_step "Installing LLM frameworks..."
    install_pip "litellm" "LiteLLM"
    install_pip "langchain" "LangChain"
    install_pip "langchain-community" "LangChain Community"
    install_pip "llama-index" "LlamaIndex"
    install_pip "fabric-ai" "Fabric" || true
    log_success "LLM frameworks completed"
}

# Install ML Python packages
install_ml_packages() {
    log_step "Installing ML Python packages..."
    install_pip "numpy" "NumPy"
    install_pip "pandas" "Pandas"
    install_pip "scipy" "SciPy"
    install_pip "scikit-learn" "Scikit-learn"
    install_pip "torch" "PyTorch"
    install_pip "transformers" "Transformers (Hugging Face)"
    install_pip "matplotlib" "Matplotlib"
    install_pip "jupyterlab" "JupyterLab"
    log_success "ML packages completed"
}

# Install AI API tools
install_api_tools() {
    log_step "Installing AI API tools..."
    install_pip "openai" "OpenAI Python"
    install_pip "anthropic" "Anthropic Python"
    install_pip "google-generativeai" "Google AI"
    log_success "AI API tools completed"
}

# Install specialized AI tools
install_specialized_ai() {
    log_step "Installing specialized AI tools..."
    install_pip "openclaw" "OpenClaw" || true
    install_pip "opencode-ai" "OpenCode" || true
    log_success "Specialized AI tools completed"
}

# Install vector databases
install_vector_dbs() {
    log_step "Installing vector database tools..."
    install_pip "chromadb" "ChromaDB"
    install_pip "pinecone-client" "Pinecone"
    log_success "Vector databases completed"
}

# Configure AI environment
configure_ai_env() {
    local shell_config="$HOME/.zshrc"
    append_if_missing "$shell_config" ""
    append_if_missing "$shell_config" "# AI Tools - Set your API keys"
    append_if_missing "$shell_config" '# export OPENAI_API_KEY="your-key-here"'
    append_if_missing "$shell_config" '# export ANTHROPIC_API_KEY="your-key-here"'
    log_success "AI environment configured"
}

# Main
main() {
    install_local_llms
    install_ai_coding
    install_llm_frameworks
    install_ml_packages
    install_api_tools
    install_specialized_ai
    install_vector_dbs
    configure_ai_env
    log_success "AI & LLM tools completed"
}

main "$@"
