#!/usr/bin/env bash
# Tear down the Minikube cluster and clean up kubeconfig entries.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

echo "============================================"
echo "  Kubernetes 1.36 in Action — Teardown"
echo "============================================"
echo ""

read -p "This will delete the Minikube profile '$MINIKUBE_PROFILE' and all demo resources. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Teardown cancelled."
    exit 0
fi

# Delete demo namespace first — this removes all namespaced demo resources at once.
if kubectl config get-contexts -o name 2>/dev/null | grep -q "^${MINIKUBE_PROFILE}$"; then
    info "Deleting demo namespace..."
    kubectl delete namespace "$DEMO_NAMESPACE" --ignore-not-found --timeout=60s || true

    # Cluster-scoped resources that the namespace delete doesn't touch.
    info "Removing cluster-scoped demo resources..."
    kubectl delete mutatingadmissionpolicy demo-label-injector --ignore-not-found 2>/dev/null || true
    kubectl delete mutatingadmissionpolicybinding demo-label-injector-binding --ignore-not-found 2>/dev/null || true
    kubectl delete volumegroupsnapshotclass demo-group-snapclass --ignore-not-found 2>/dev/null || true
else
    warn "Context '$MINIKUBE_PROFILE' not found. Skipping namespace cleanup."
fi

# Delete Minikube profile
if minikube status -p "$MINIKUBE_PROFILE" &> /dev/null; then
    info "Deleting Minikube profile '$MINIKUBE_PROFILE'..."
    minikube delete -p "$MINIKUBE_PROFILE"
else
    warn "Minikube profile '$MINIKUBE_PROFILE' not found."
fi

# Clean up any leftover kubeconfig entries
info "Cleaning up kubectl contexts..."
kubectl config delete-context "$MINIKUBE_PROFILE" 2>/dev/null || true
kubectl config delete-cluster "$MINIKUBE_PROFILE" 2>/dev/null || true
kubectl config unset "users.$MINIKUBE_PROFILE" 2>/dev/null || true

echo ""
info "Teardown complete. All resources have been removed."
info "To start fresh, run: ./01-install-prerequisites.sh && ./02-start-cluster.sh"
