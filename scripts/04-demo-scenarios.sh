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

wait_for_user() {
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

show_pods() {
    echo -e "${CYAN}Current pods:${NC}"
    kubectl get pods -n "$NAMESPACE" -o wide
}

echo "============================================"
echo "  Kubernetes 1.36 in Action — Demo Scenarios"
echo "============================================"
echo ""

echo "Make sure you have the demo deployed:"
echo "  ./03-deploy-app.sh"
echo ""
echo "And have port-forward running in another terminal:"
echo "  kubectl port-forward svc/demo-app-service 8080:80 -n $NAMESPACE"
echo ""
echo "Watch pods in another terminal:"
echo "  kubectl get pods -n $NAMESPACE -w"
wait_for_user

# Scenario 1: User Namespaces
header "Scenario 1: User Namespaces (Stable — 9 years to GA)"
info "Container root maps to an unprivileged UID on the host. Breaking out grants nothing."
echo ""
info "User Namespaces demo pod:"
kubectl get pod user-ns-demo -n "$NAMESPACE" 2>/dev/null || info "Pod not running (requires compatible runtime + kernel 5.12+)"
echo ""
if kubectl get pod user-ns-demo -n "$NAMESPACE" &>/dev/null; then
    info "Inside the container — appears to be root:"
    kubectl exec user-ns-demo -n "$NAMESPACE" -- id 2>/dev/null || true
    echo ""
    info "But hostUsers: false means it maps to an unprivileged UID on the host"
    kubectl get pod user-ns-demo -n "$NAMESPACE" -o jsonpath='{.spec.hostUsers}' 2>/dev/null; echo ""
fi
echo ""
info "Enable with just: spec.hostUsers: false"
wait_for_user

# Scenario 2: MutatingAdmissionPolicy
header "Scenario 2: MutatingAdmissionPolicy (Stable)"
info "Replace webhooks with native CEL — no server, no TLS certs, no 2am incidents"
echo ""
info "MutatingAdmissionPolicies in cluster:"
kubectl get mutatingadmissionpolicies 2>/dev/null || info "MutatingAdmissionPolicy CRD not available"
echo ""
info "To test: create a pod and check if labels were auto-injected"
echo "  kubectl run test-cel --image=nginx -n $NAMESPACE"
echo "  kubectl get pod test-cel -n $NAMESPACE -o jsonpath='{.metadata.labels}'"
wait_for_user

# Scenario 3: Fine-grained Authorization
header "Scenario 3: Fine-grained Kubelet Authorization (Stable)"
info "Node credentials scoped — a node can only read secrets for its own pods"
echo ""
info "Current KubeletAuthorizationPolicies:"
kubectl get kubeletauthorizationpolicies -n "$NAMESPACE" 2>/dev/null || info "No policies found (feature is GA and locked on by default)"
echo ""
info "Service accounts in demo namespace:"
kubectl get serviceaccounts -n "$NAMESPACE"
echo ""
info "The demo-monitoring service account has limited kubelet access via the policy"
wait_for_user

# Scenario 4: Volume Group Snapshots
header "Scenario 4: Volume Group Snapshots (Stable)"
info "This demonstrates crash-consistent snapshots across multiple PVCs"
echo ""
info "Current PVCs:"
kubectl get pvc -n "$NAMESPACE"
echo ""
info "VolumeGroupSnapshotClasses:"
kubectl get volumegroupsnapshotclasses 2>/dev/null || info "No group snapshot classes (requires CSI driver support)"
echo ""
info "To create a group snapshot manually:"
echo "  kubectl apply -f $PROJECT_DIR/k8s/volume-group-snapshot.yaml"
wait_for_user

# Scenario 5: Resource Health Status
header "Scenario 5: Resource Health Status (Beta)"
info "This demonstrates native hardware health reporting in pod status"
echo ""
info "Checking for device health information in pods:"
kubectl describe pods -n "$NAMESPACE" | grep -A 10 "Allocated Resources Status" || {
    info "No device health status available (normal without GPU/specialized hardware)"
    info "This feature shines with actual hardware devices attached"
}
echo ""
info "To see this feature with real hardware, deploy pods requesting GPU/FPGA resources"
wait_for_user

# Scenario 6: Workload Aware Scheduling
header "Scenario 6: Workload Aware Scheduling (Alpha)"
info "This demonstrates gang scheduling where related pods are scheduled atomically"
echo ""
info "Current Workloads:"
kubectl get workloads -n "$NAMESPACE" 2>/dev/null || info "No Workloads found (feature requires WorkloadAwareScheduling enabled)"
echo ""
info "Current PodGroups:"
kubectl get podgroups -n "$NAMESPACE" 2>/dev/null || info "No PodGroups found (feature requires WorkloadAwareScheduling enabled)"
echo ""
info "Demo includes Workload + PodGroup v1alpha2 manifests for gang scheduling"
show_pods
echo ""
info "To test WAS manually:"
echo "  kubectl apply -f $PROJECT_DIR/k8s/podgroup.yaml"
wait_for_user

# Scenario 7: HPA Scale to Zero
header "Scenario 7: HPA Scale to Zero (Alpha)"
info "This demonstrates true serverless scaling - HPA can scale deployments to zero"
echo ""
info "Current HPAs:"
kubectl get hpa -n "$NAMESPACE"
echo ""
info "The HPA defaults to minReplicas: 1. To test scale-to-zero, enable HPAScaleToZero feature gate + add an Object metric."
echo "Current replica count for demo-app:"
kubectl get deployment demo-app -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null; echo " desired"
kubectl get deployment demo-app -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null; echo " ready"
echo ""
info "With minReplicas: 1, the HPA won't scale below 1. See k8s/demo-hpa.yaml for scale-to-zero instructions."
wait_for_user

# Scenario 8: Multi-feature Integration
header "Scenario 8: Multi-feature Integration Demo"
info "Observe how multiple K8s 1.36 features work together in the demo app"
echo ""
info "Complete demo application status:"
kubectl get all -n "$NAMESPACE"
echo ""
info "Key observations:"
echo "  • User Namespaces demonstrated via user-namespaces-pod.yaml (requires containerd 2.x)"
echo "  • MutatingAdmissionPolicy auto-injects labels via CEL"
echo "  • Fine-grained authz service account with scoped kubelet access"
echo "  • Multiple PVCs ready for group snapshot testing"
echo "  • HPA configured for scale-to-zero behavior"
echo "  • Workload + PodGroup v1alpha2 for gang scheduling"
echo "  • NetworkPolicy and ResourceQuota demonstrate security best practices"
echo ""
show_pods
wait_for_user

# Scenario 9: Feature Verification
header "Scenario 9: Feature Verification & Diagnostics"
info "Running inline feature verification..."
echo ""

info "Cluster version:"
kubectl version --short 2>/dev/null || kubectl version
echo ""

info "Installed CRDs (K8s 1.36 relevant):"
kubectl get crd 2>/dev/null | grep -E '(snapshot|scheduling|node|resource)' || info "No K8s 1.36 CRDs detected"
echo ""

info "System pods health:"
kubectl get pods -n kube-system --no-headers 2>/dev/null | awk '{print $1, $3}' | head -10
echo ""

info "Node status:"
kubectl get nodes -o wide
echo ""

info "Manual verification commands:"
echo "  kubectl version --short"
echo "  kubectl get crd | grep -E '(snapshot|scheduling|node)'"
echo "  kubectl get nodes -o yaml | grep -i feature-gates | head -1"
echo ""

header "Demo Complete"
info "You have explored all major Kubernetes 1.36 features! (9 scenarios)"
echo ""
info "Next steps:"
echo "  1. Read the Medium story: docs/kubernetes-1-36-medium-story.md"
echo "  2. Explore individual feature directories for deeper examples"
echo "  3. Try deploying on a real K8s 1.36 cluster with feature gates enabled"
echo "  4. Clean up with: ./05-teardown.sh"
echo ""
info "Happy Kubernetes 1.36 exploring! 🌸"
