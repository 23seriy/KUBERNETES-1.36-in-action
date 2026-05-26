#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

print_diagnostics() {
    warn "Some components did not become ready in time. Collecting diagnostics..."
    echo ""
    kubectl get nodes -o wide || true
    echo ""
    kubectl get pods -n kube-system || true
    echo ""
    kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 30 || true
}

PROFILE="k8s136-in-action"
TARGET_K8S_VERSION="v1.36.0"

echo "============================================"
echo "  Kubernetes 1.36 in Action — Cluster Setup"
echo "============================================"
echo ""

if minikube status -p "$PROFILE" &> /dev/null; then
    info "Minikube cluster '$PROFILE' is already running"
    warn "This script expects Kubernetes ${TARGET_K8S_VERSION}. If this cluster was created earlier with an older version, recreate it with: minikube delete -p $PROFILE"
else
    info "Starting Minikube cluster '$PROFILE'..."
    minikube start \
        --profile="$PROFILE" \
        --cpus=6 \
        --memory=8192 \
        --driver=docker \
        --kubernetes-version="$TARGET_K8S_VERSION"
fi

info "Setting kubectl context to '$PROFILE'..."
kubectl config use-context "$PROFILE"

# Enable required addons (ingress is not used by the demo)
info "Enabling Minikube addons..."
minikube addons enable metrics-server -p "$PROFILE" || true

# Wait for control plane
info "Waiting for control plane to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || {
    print_diagnostics
    exit 1
}

echo ""
info "Cluster is ready."

# Print useful info
echo ""
info "Cluster info:"
kubectl cluster-info
echo ""
info "To access the dashboard (optional):"
echo "  minikube dashboard -p $PROFILE"
