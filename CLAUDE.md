# CLAUDE.md — Kubernetes 1.36 in Action

## Project Overview

Hands-on demo of **Kubernetes 1.36 "ハル (Haru)"** features through practical examples. Covers stable, beta, and alpha features — from fine-grained authorization to workload-aware scheduling. No apps to build — this project focuses on Kubernetes-native resources and feature gates.

## Tech Stack

- **Platform**: Minikube (profile: `k8s136-in-action`) running Kubernetes 1.36
- **Demo namespace**: `k8s136-demo`
- **Tools**: kubectl, minikube, helm (installed; used by individual feature demos)
- **No application code** — pure Kubernetes manifests and feature demos

## Project Structure

```
stable-features/       # GA features in 1.36
  fine-grained-authz/  # Field/label selector authorization
  volume-group-snapshots/ # Consistent multi-volume snapshots
beta-features/         # Beta features in 1.36
  resource-health-status/ # Pod resource health conditions
alpha-features/        # Alpha features (require feature gates)
  workload-aware-scheduling/ # Schedule based on workload state
deployment-examples/   # General deployment patterns
docs/                  # Additional documentation
k8s/                   # Base Kubernetes manifests
scripts/               # Numbered automation scripts (01–05)
```

## Scripts Convention

All scripts are in `scripts/` and numbered sequentially:
- `01-install-prerequisites.sh` — Verifies/installs minikube, kubectl, helm, docker via Homebrew
- `02-start-cluster.sh` — Creates Minikube cluster on K8s 1.36 and enables `metrics-server` addon
- `03-deploy-app.sh` — Applies the namespace, core resources, and feature-specific manifests (best-effort for CRD-dependent ones)
- `04-demo-scenarios.sh` — Interactive walkthrough of nine 1.36 feature scenarios
- `05-teardown.sh` — Destroys cluster (has confirmation prompt, cleans kubeconfig entries and cluster-scoped resources)

Scripts use `#!/usr/bin/env bash`, `set -euo pipefail`, and source `scripts/lib/common.sh` for shared helpers (colors, info/warn/error/header, profile/namespace constants).

## Key Concepts

- **Feature gates** are enabled on the Minikube cluster via `--feature-gates` flag
- **Stable features** work out of the box on any 1.36 cluster
- **Beta features** are enabled by default but can be toggled
- **Alpha features** require explicit feature gate enablement
- Each feature directory is self-contained with its own manifests and README
- The teardown script is more comprehensive than other repos — it cleans kubeconfig entries and handles CRDs

## Conventions

- All Kubernetes resources use the `k8s136-demo` namespace
- Feature directories are organized by maturity level (stable → beta → alpha)
- Color-coded `[INFO] / [WARN] / [ERROR]` script output from `scripts/lib/common.sh`
- Container image tags are pinned (no bare `:latest`)
- Pods that aren't specifically demonstrating a security feature apply Pod Security Standards (`restricted` profile)
- No application code — all demos use standard Kubernetes resources or pinned public images
