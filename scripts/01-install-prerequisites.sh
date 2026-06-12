#!/usr/bin/env bash
# Verify and install local prerequisites (minikube, kubectl, helm, docker).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Check if a Homebrew formula has a newer version available.
# Usage: check_brew_upgrade <formula>
check_brew_upgrade() {
    local formula="$1"
    if brew outdated --formula 2>/dev/null | grep -qw "$formula"; then
        warn "$formula can be upgraded — run: brew upgrade $formula"
    fi
}

echo "============================================"
echo "  Kubernetes 1.36 in Action — Prerequisites"
echo "============================================"
echo ""

if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is designed for macOS. Adjust package manager commands for your OS."
    exit 1
fi

if ! command -v brew &> /dev/null; then
    error "Homebrew is required. Install it from https://brew.sh"
    exit 1
fi

if command -v minikube &> /dev/null; then
    info "minikube already installed: $(minikube version --short 2>/dev/null || minikube version | head -1)"
else
    info "Installing minikube..."
    brew install minikube
fi

if command -v kubectl &> /dev/null; then
    info "kubectl already installed: $(kubectl version --client 2>/dev/null | head -1)"
else
    info "Installing kubectl..."
    brew install kubectl
fi

if command -v helm &> /dev/null; then
    info "helm already installed: $(helm version --short 2>/dev/null)"
else
    info "Installing helm..."
    brew install helm
fi

if command -v docker &> /dev/null; then
    info "Docker already installed: $(docker --version)"
else
    error "Docker is required. Install Docker Desktop from https://docker.com"
    exit 1
fi

echo ""
echo "Checking for available upgrades..."
check_brew_upgrade minikube
check_brew_upgrade kubernetes-cli
check_brew_upgrade helm

if ! brew outdated --formula 2>/dev/null | grep -qwE 'minikube|kubernetes-cli|helm'; then
    info "All Homebrew tools are up to date."
fi

echo ""
info "All prerequisites are ready."
