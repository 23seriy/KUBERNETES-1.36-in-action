# CLAUDE.md — Kubernetes 1.36 in Action

## Project Overview

Hands-on demo of **Kubernetes 1.36 "ハル (Haru)"** features through practical examples. Covers stable, beta, and alpha features — from fine-grained authorization to workload-aware scheduling. No apps to build — this project focuses on Kubernetes-native resources and feature gates.

## Tech Stack

- **Platform**: Minikube (profile: `k136-demo`) running Kubernetes 1.36
- **Tools**: kubectl, minikube
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
- `01-install-prerequisites.sh` — Installs minikube, kubectl via Homebrew
- `02-start-cluster.sh` — Creates Minikube cluster with K8s 1.36 and required feature gates
- `03-deploy-app.sh` — Deploys base resources for demos
- `04-demo-scenarios.sh` — Interactive walkthrough of 1.36 features
- `05-teardown.sh` — Destroys cluster (has confirmation prompt, cleans kubeconfig entries and CRDs)

Scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.

## Key Concepts

- **Feature gates** are enabled on the Minikube cluster via `--feature-gates` flag
- **Stable features** work out of the box on any 1.36 cluster
- **Beta features** are enabled by default but can be toggled
- **Alpha features** require explicit feature gate enablement
- Each feature directory is self-contained with its own manifests and README
- The teardown script is more comprehensive than other repos — it cleans kubeconfig entries and handles CRDs

## Conventions

- All Kubernetes resources use the `k136-demo` namespace
- Feature directories are organized by maturity level (stable → beta → alpha)
- Emoji prefixes in script output for readability (🌸, ✅, 🗑️)
- No Docker images — all demos use standard Kubernetes resources or public images
