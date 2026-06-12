#!/usr/bin/env bash
# Create or start the Minikube cluster targeting Kubernetes 1.36.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

print_diagnostics() {
    warn "Some components did not become ready in time. Collecting diagnostics..."
    echo ""
    kubectl get nodes -o wide || true
    echo ""
    kubectl get pods -n kube-system || true
    echo ""
    kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 30 || true
}

echo "============================================"
echo "  Kubernetes 1.36 in Action — Cluster Setup"
echo "============================================"
echo ""

if minikube status -p "$MINIKUBE_PROFILE" &> /dev/null; then
    info "Minikube cluster '$MINIKUBE_PROFILE' is already running"
    warn "This script expects Kubernetes ${TARGET_K8S_VERSION}. If this cluster was created earlier with an older version, recreate it with: minikube delete -p $MINIKUBE_PROFILE"
else
    info "Starting Minikube cluster '$MINIKUBE_PROFILE'..."
    minikube start \
        --profile="$MINIKUBE_PROFILE" \
        --cpus=6 \
        --memory=8192 \
        --driver=docker \
        --kubernetes-version="$TARGET_K8S_VERSION"
fi

info "Setting kubectl context to '$MINIKUBE_PROFILE'..."
kubectl config use-context "$MINIKUBE_PROFILE"

info "Enabling Minikube addons..."
minikube addons enable metrics-server -p "$MINIKUBE_PROFILE" || true

info "Waiting for control plane to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || {
    print_diagnostics
    exit 1
}

echo ""
info "Cluster is ready."
echo ""
info "Cluster info:"
kubectl cluster-info
echo ""
info "To access the dashboard (optional):"
echo "  minikube dashboard -p $MINIKUBE_PROFILE"
