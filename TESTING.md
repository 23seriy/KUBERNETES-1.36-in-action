# Testing Guide

## Overview

This project relies on local validation, shell script linting, YAML linting, and manual end-to-end scenario testing. There is no application code to unit-test — testing means verifying that the Kubernetes 1.36 feature demos behave as documented.

## Prerequisites

- Minikube running with the `k8s136-in-action` profile
- Demo deployed via `./scripts/03-deploy-app.sh`

## Automated Checks

### Shell Script Linting

```bash
shellcheck -x scripts/*.sh
```

All scripts must pass with zero warnings. The `.shellcheckrc` file disables `SC1091` for sourced-file resolution (`scripts/lib/common.sh`).

### YAML Validation

```bash
yamllint -d relaxed k8s/*.yaml
```

### Manifest Dry-Run

```bash
for f in k8s/*.yaml; do
  kubectl apply --dry-run=client -f "$f"
done
```

This catches schema errors before applying to a real cluster.

### Markdown Linting

```bash
npx markdownlint-cli2 "**/*.md" --config .markdownlint.json
```

### Bash Syntax

```bash
for s in scripts/*.sh; do bash -n "$s"; done
```

## CI/CD (GitHub Actions)

The `.github/workflows/validate.yml` workflow runs on every push and PR to `main`:

| Job | What It Checks |
|---|---|
| `shellcheck` | All `scripts/*.sh` pass shellcheck |
| `yaml-lint` | All K8s YAML files pass yamllint |
| `script-syntax` | All scripts pass `bash -n` |
| `docs-check` | Required documentation files exist |
| `markdown-lint` | All Markdown files pass markdownlint |

## Manual Scenario Testing

### Full Workflow Test

Run all scenarios end-to-end:

```bash
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
./scripts/03-deploy-app.sh
./scripts/04-demo-scenarios.sh
```

### Individual Feature Tests

#### 1. User Namespaces (Stable)

```bash
kubectl get pod user-ns-demo -n k8s136-demo -o jsonpath='{.spec.hostUsers}'
# Expected: "false"
kubectl exec user-ns-demo -n k8s136-demo -- id
# Expected: uid=0(root) inside, but maps to unprivileged UID on the host
```

**Note**: Requires containerd 2.x and kernel 5.12+. Minikube's Docker driver does **not** support this — the pod will fail to start.

#### 2. MutatingAdmissionPolicy (Stable)

```bash
kubectl run cel-test --image=busybox:1.36 -n k8s136-demo --command -- sleep 60
kubectl get pod cel-test -n k8s136-demo -o jsonpath='{.metadata.labels}' | jq .
# Expected: contains "managed-by": "k8s136-cel-policy" and "demo": "mutating-admission"
kubectl delete pod cel-test -n k8s136-demo
```

#### 3. Fine-grained Kubelet Authorization (Stable)

```bash
kubectl get kubeletauthorizationpolicies -n k8s136-demo
# Expected: demo-monitoring-policy exists
kubectl logs demo-monitoring -n k8s136-demo
# Expected: /metrics and /healthz return 200; /pods returns 403
```

#### 4. Volume Group Snapshots (Stable)

```bash
kubectl get volumegroupsnapshotclasses
kubectl get volumegroupsnapshots -n k8s136-demo
# Expected: snapshot becomes ReadyToUse=True with a CSI driver that supports it
```

#### 5. ImageVolume (Stable)

```bash
kubectl logs image-volume-demo -n k8s136-demo
# Expected: lists OCI image contents, write attempt is denied
```

#### 6. Resource Health Status (Beta)

```bash
kubectl describe pods -n k8s136-demo | grep -A 10 "Allocated Resources Status"
# Expected: visible when GPU/FPGA resources are attached
```

#### 7. Workload Aware Scheduling (Alpha)

```bash
kubectl get workloads -n k8s136-demo
kubectl get podgroups -n k8s136-demo
# Expected: Both exist; requires WorkloadAwareScheduling feature gate
```

#### 8. HPA Scale to Zero (Alpha)

```bash
kubectl get hpa demo-app-hpa -n k8s136-demo
# Expected: minReplicas: 1 by default; change to 0 with HPAScaleToZero feature gate + Object/External metric
```

## Component Testing

### Cluster Health

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl version --client
```

### Demo Namespace Health

```bash
kubectl get all -n k8s136-demo
kubectl get events -n k8s136-demo --sort-by=.metadata.creationTimestamp | tail -n 20
```

## Regression Testing

After any code change, verify:

1. Fresh cluster setup works: `02-start-cluster.sh` → `03-deploy-app.sh`
2. All nine scenarios in `04-demo-scenarios.sh` complete without errors
3. Teardown is clean: `05-teardown.sh` removes the cluster and all kubeconfig entries

## Debugging Failed Tests

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common failures.

---

Questions about testing? Open an issue! 🌸
