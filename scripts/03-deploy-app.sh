#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

NAMESPACE="k8s136-demo"

echo "============================================"
echo "  Kubernetes 1.36 in Action — Deploy Demo"
echo "============================================"
echo ""

# Ensure namespace exists
info "Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy core resources
header "Deploying Core Resources"
info "Applying K8s manifests from k8s/ directory..."
kubectl apply -f "$PROJECT_DIR/k8s/namespace.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-configmap.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-monitoring-sa.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-pvcs.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-app.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-app-service.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-network-policy.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-resource-quota.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-monitoring-pod.yaml"
kubectl apply -f "$PROJECT_DIR/k8s/demo-hpa.yaml"

# Wait for key components
info "Waiting for demo app deployment..."
kubectl wait --for=condition=available deployment/demo-app -n "$NAMESPACE" --timeout=180s || {
    warn "Demo app deployment not ready within timeout"
}

info "Waiting for monitoring pod..."
kubectl wait --for=condition=Ready pod/demo-monitoring -n "$NAMESPACE" --timeout=120s || {
    warn "Monitoring pod not ready within timeout"
}

# Deploy feature-specific manifests (CRDs may not exist; apply best-effort)
header "Deploying Feature-Specific Resources"
info "Applying fine-grained authz policy..."
kubectl apply -f "$PROJECT_DIR/k8s/fine-grained-authz-policy.yaml" 2>/dev/null || warn "KubeletAuthorizationPolicy CRD not available (expected without feature gate)"

info "Applying PodGroup for workload-aware scheduling..."
kubectl apply -f "$PROJECT_DIR/k8s/podgroup.yaml" 2>/dev/null || warn "PodGroup CRD not available (expected without feature gate)"

info "Applying volume group snapshot resources..."
kubectl apply -f "$PROJECT_DIR/k8s/volume-group-snapshot.yaml" 2>/dev/null || warn "VolumeGroupSnapshot CRDs not available (requires CSI driver support)"

info "Deploying User Namespaces demo pod..."
kubectl apply -f "$PROJECT_DIR/k8s/user-namespaces-pod.yaml" 2>/dev/null || warn "User Namespaces requires compatible runtime and kernel 5.12+"

info "Deploying ImageVolume demo pod..."
kubectl apply -f "$PROJECT_DIR/k8s/image-volume-pod.yaml" 2>/dev/null || warn "ImageVolume requires ImageVolume feature gate"

info "Applying MutatingAdmissionPolicy..."
kubectl apply -f "$PROJECT_DIR/k8s/mutating-admission-policy.yaml" 2>/dev/null || warn "MutatingAdmissionPolicy CRD not available (requires 1.36+)"

# Verify deployment
header "Deployment Verification"
info "Checking deployed resources..."

echo ""
info "Pods in $NAMESPACE:"
kubectl get pods -n "$NAMESPACE" -o wide

echo ""
info "Deployments in $NAMESPACE:"
kubectl get deployments -n "$NAMESPACE"

echo ""
info "Services in $NAMESPACE:"
kubectl get services -n "$NAMESPACE"

echo ""
info "CRDs installed (relevant to K8s 1.36 features):"
kubectl get crd | grep -E "(snapshot|scheduling|node)" || info "No K8s 1.36 CRDs found (expected in fresh cluster)"

echo ""
header "Access Instructions"
info "Demo application is ready!"
echo ""
echo "To access the demo:"
echo "  kubectl port-forward svc/demo-app-service 8080:80 -n $NAMESPACE"
echo ""
echo "Then open: http://localhost:8080"
echo ""
echo "To watch feature demonstrations:"
echo "  kubectl get pods -n $NAMESPACE -w"
echo ""
echo "To check device health status (if available):"
echo "  kubectl describe pod demo-app-xxxxx -n $NAMESPACE"
echo ""
echo "To test fine-grained authorization:"
echo "  kubectl get kubeletauthorizationpolicies -n $NAMESPACE"
echo ""

info "Demo deployment complete! 🎉"
