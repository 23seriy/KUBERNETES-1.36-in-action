#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

PROFILE="k8s136-in-action"
NAMESPACE="k8s136-demo"

echo "============================================"
echo "  Kubernetes 1.36 in Action — Teardown"
echo "============================================"
echo ""

read -p "This will delete the Minikube profile '$PROFILE' and all demo resources. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Teardown cancelled."
    exit 0
fi

# Clean up namespace resources if cluster is still accessible
if kubectl config get-contexts | grep -q "$PROFILE"; then
    info "Cleaning up demo namespace..."
    kubectl delete namespace "$NAMESPACE" --ignore-not-found --timeout=60s || true
    
    # Clean up any lingering CRDs we may have created
    info "Cleaning up any test CRDs..."
    kubectl delete kubeletauthorizationpolicies --all -n "$NAMESPACE" --ignore-not-found 2>/dev/null || true
    kubectl delete podgroups --all -n "$NAMESPACE" --ignore-not-found 2>/dev/null || true
    kubectl delete volumegroupsnapshots --all -n "$NAMESPACE" --ignore-not-found 2>/dev/null || true
else
    warn "Context '$PROFILE' not found. Skipping namespace cleanup."
fi

# Delete Minikube profile
if minikube status -p "$PROFILE" &> /dev/null 2>&1; then
    info "Deleting Minikube profile '$PROFILE'..."
    minikube delete -p "$PROFILE"
else
    warn "Minikube profile '$PROFILE' not found."
fi

# Clean up any leftover kubeconfig entries
info "Cleaning up kubectl contexts..."
kubectl config delete-context "$PROFILE" 2>/dev/null || true
kubectl config delete-cluster "$PROFILE" 2>/dev/null || true
kubectl config unset "users.$PROFILE" 2>/dev/null || true

echo ""
info "Teardown complete. All resources have been removed."
info "To start fresh, run: ./01-install-prerequisites.sh && ./02-start-cluster.sh"
