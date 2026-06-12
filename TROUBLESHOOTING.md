# Troubleshooting Guide

## Quick Diagnostics

Run these commands to get a snapshot of the demo state:

```bash
minikube status -p k8s136-in-action
kubectl get nodes -o wide
kubectl get pods -n k8s136-demo
kubectl get events -n k8s136-demo --sort-by=.metadata.creationTimestamp | tail -n 30
```

---

## Installation Issues

### Minikube Won't Start

**Symptom**: `minikube start` fails or hangs.

**Fix**:

```bash
docker info                              # confirm Docker Desktop is running
minikube delete -p k8s136-in-action      # remove stale profile
./scripts/02-start-cluster.sh
```

**Cause**: Docker daemon not running, or a leftover profile from a previous run.

### Homebrew Tools Not Found

**Symptom**: `minikube`, `kubectl`, or `helm` not found after running `01-install-prerequisites.sh`.

**Fix**:

```bash
exec "$SHELL"                            # reload shell
./scripts/01-install-prerequisites.sh    # re-run install
```

### Kubernetes Version Mismatch

**Symptom**: `02-start-cluster.sh` reports the cluster is on an older version.

**Fix**:

```bash
minikube delete -p k8s136-in-action
./scripts/02-start-cluster.sh
```

The start script always targets `v1.36.0`. Existing clusters from previous runs must be recreated.

---

## Feature Gate Issues

Many K8s 1.36 features require explicit feature-gate enablement on the cluster.

### ImageVolume Pod Fails to Start

**Symptom**: `image-volume-demo` pod is stuck in `Pending` or `CreateContainerConfigError`.

**Fix**: Start Minikube with the `ImageVolume` feature gate:

```bash
minikube delete -p k8s136-in-action
minikube start -p k8s136-in-action \
  --kubernetes-version=v1.36.0 \
  --feature-gates=ImageVolume=true
```

### MutatingAdmissionPolicy Not Applied

**Symptom**: Pods created in `k8s136-demo` don't have the auto-injected labels.

**Fix**: The `MutatingAdmissionPolicy` API is GA in 1.36 but the binding only matches namespaces with label `demo: kubernetes-1.36`. Verify the namespace label:

```bash
kubectl get namespace k8s136-demo --show-labels
```

If the label is missing:

```bash
kubectl label namespace k8s136-demo demo=kubernetes-1.36 --overwrite
```

### User Namespaces Pod Fails

**Symptom**: `user-ns-demo` pod is stuck or fails with runtime errors.

**Cause**: Minikube's Docker driver does not support `hostUsers: false`. You need a runtime that does.

**Fix**:

```bash
minikube delete -p k8s136-in-action
minikube start -p k8s136-in-action \
  --kubernetes-version=v1.36.0 \
  --container-runtime=containerd
```

You also need a host kernel with ID-mapped mount support (5.12+).

### Workload Aware Scheduling CRDs Missing

**Symptom**: `kubectl apply -f k8s/podgroup.yaml` fails with "no matches for kind".

**Cause**: WAS is alpha; the CRDs are not installed by default.

**Fix**: Enable the feature gate and install the CRDs from the upstream repo:

```bash
minikube start -p k8s136-in-action \
  --kubernetes-version=v1.36.0 \
  --feature-gates=WorkloadAwareScheduling=true
# Then apply the v1alpha2 CRDs from kubernetes-sigs/scheduler-plugins
```

### HPAScaleToZero Doesn't Scale to Zero

**Symptom**: HPA's `minReplicas: 0` is rejected, or replicas never reach 0.

**Cause**: Two requirements: (a) the `HPAScaleToZero` feature gate must be on, and (b) the HPA must have at least one `Object` or `External` metric (Resource metrics alone cannot drive scale-to-zero).

**Fix**: See the inline comments in `k8s/demo-hpa.yaml`.

---

## Deployment Issues

### Pods Stuck in `ImagePullBackOff`

**Symptom**: Demo pods can't pull images.

**Fix**:

```bash
kubectl describe pod -n k8s136-demo <pod>      # look at the events
```

Usually a Docker Hub rate-limit or a typo in the image reference. The demo uses public images; verify network connectivity.

### Demo App Not Ready

**Symptom**: `demo-app` Deployment never reaches Available.

**Fix**:

```bash
kubectl describe deployment demo-app -n k8s136-demo
kubectl logs deployment/demo-app -n k8s136-demo -c web-server
kubectl logs deployment/demo-app -n k8s136-demo -c log-processor
```

Common causes: PVC pending (storage class issue), insufficient cluster resources.

### PVC Stuck in `Pending`

**Symptom**: `demo-data-pvc` or `demo-logs-pvc` never bind.

**Fix**:

```bash
kubectl get storageclass
kubectl describe pvc -n k8s136-demo
```

The manifests assume Minikube's default `standard` storage class. If you're on a different cluster, edit `k8s/demo-pvcs.yaml`.

### Port-Forward Drops

**Symptom**: `http://localhost:8080` stops responding.

**Fix**:

```bash
kubectl port-forward svc/demo-app-service 8080:80 -n k8s136-demo
```

Port-forwards drop if the pod restarts or if the connection sits idle too long.

### NetworkPolicy Blocking Traffic

**Symptom**: Traffic to `demo-app` is blocked even though pods are healthy.

**Fix**: Review `k8s/demo-network-policy.yaml`. The policy restricts ingress to the same namespace and egress to DNS + the API server. If you want broader connectivity for experimentation:

```bash
kubectl delete networkpolicy demo-network-policy -n k8s136-demo
```

---

## Teardown Issues

### Teardown Script Hangs

**Symptom**: `05-teardown.sh` hangs during namespace deletion.

**Fix**: Finalizers may block deletion:

```bash
kubectl get namespace k8s136-demo -o json \
  | jq '.spec.finalizers = []' \
  | kubectl replace --raw "/api/v1/namespaces/k8s136-demo/finalize" -f -
```

### Minikube Profile Not Deleted

**Symptom**: `minikube delete -p k8s136-in-action` fails.

**Fix**:

```bash
minikube delete -p k8s136-in-action --purge
```

---

## Collecting Diagnostics

If you need to file a bug report, collect:

```bash
echo "=== Minikube ==="
minikube status -p k8s136-in-action

echo "=== Nodes ==="
kubectl get nodes -o wide

echo "=== Demo Namespace ==="
kubectl get all -n k8s136-demo

echo "=== Events ==="
kubectl get events -n k8s136-demo --sort-by=.metadata.creationTimestamp | tail -n 50

echo "=== CRDs (1.36 features) ==="
kubectl get crd | grep -E '(snapshot|scheduling|node|admission)'

echo "=== Cluster Version ==="
kubectl version --client
kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}'
```

---

Still stuck? Open an [issue](https://github.com/23seriy/kubernetes-1.36-in-action/issues) with your diagnostics output! 🌸
