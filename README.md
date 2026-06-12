# 🌸 Kubernetes 1.36 "ハル (Haru)" — Complete Guide with Examples

A hands-on project for learning **Kubernetes 1.36** features through practical examples. This release brings 70 enhancements across Stable, Beta, and Alpha maturity levels — from fine-grained authorization to workload-aware scheduling.

Instead of just reading release notes, this project lets you **deploy, test, and break** real K8s 1.36 features on your laptop with Minikube.

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.36-326CE5?logo=kubernetes&logoColor=white)
![Minikube](https://img.shields.io/badge/Minikube-local-F7B93E?logo=kubernetes&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)

> 📝 **Published article:** [Kubernetes 1.36 "ハル (Haru)": The Future of Container Orchestration is Here](https://medium.com/@sergeiolshanetski/kubernetes-1-36-%E3%83%8F%E3%83%AB-haru-the-future-of-container-orchestration-is-here-232dbc1592c7)

## 🏗️ Architecture

```text
                 ┌──────────────────────────────────────────────────┐
                 │                 Minikube Cluster                  │
                 │                                                  │
 User ────────►  │  Complete Demo App (multi-feature showcase)       │
                 │  • User Namespaces pod (hostUsers: false)          │
                 │  • MutatingAdmissionPolicy (CEL labels)           │
                 │  • Fine-grained kubelet authorization             │
                 │  • Multi-PVC setup for group snapshots            │
                 │  • ImageVolume (OCI artifact as volume)           │
                 │  • HPA with scale-to-zero                         │
                 │  • Workload + PodGroup v1alpha2 for WAS           │
                 │                                                  │
                 │  Feature-Specific Deep-Dives:                    │
                 │  • KubeletAuthorizationPolicies (stable/)         │
                 │  • VolumeGroupSnapshots v1 (stable/)              │
                 │  • Resource health status (beta/)                 │
                 │  • Workload Aware Scheduling (alpha/)             │
                 └──────────────────────────────────────────────────┘
```

## 📋 What You'll Learn

| K8s 1.36 Feature | Maturity | What It Does | Demo Scenario |
|---|---|---|---|
| **User Namespaces** | Stable | Container root maps to unprivileged host UID — 9 years to GA | `hostUsers: false` isolates container escapes |
| **MutatingAdmissionPolicy** | Stable | Mutate resources with CEL — no webhook server needed | Auto-inject labels without TLS ceremony |
| **Fine-grained Kubelet Authorization** | Stable | Node credentials scoped — no cross-node secret reads | Monitoring tools get only `/metrics` and `/healthz` |
| **Volume Group Snapshots** | Stable | Crash-consistent snapshots across multiple PVCs | Database with separate data + logs volumes |
| **Dynamic Resource Allocation (DRA)** | Stable | GPU sharing, prioritized alternatives, admin access | AI/ML workloads with H100→A100→T4 fallback |
| **ImageVolume (OCI Artifacts)** | Stable | Mount OCI images as read-only volumes | ML model weights without init containers |
| **Node Log Query** | Stable | Retrieve node logs via API — no SSH | `kubectl get --raw .../proxy/logs/` |
| **Resource Health Status** | Beta | Native hardware health in `kubectl describe pod` | Detect faulty GPUs without external monitoring |
| **Mixed Version Proxy** | Beta | API server proxies unknown resources to newer instances | Rolling upgrades without 404s |
| **Memory QoS** | Beta | `memory.min` / `memory.low` guarantees with cgroups v2 | Prevent OOM kills from noisy neighbors |
| **Workload Aware Scheduling (WAS)** | Alpha | Workload + PodGroup API split, topology-aware gang scheduling | Distributed ML training with rack co-location |
| **HPA Scale to Zero** | Alpha | True serverless scaling for custom metrics | Event-driven apps that disappear when idle |

## 🚀 Quick Start

### Step 0: Clone the Repository

```bash
git clone https://github.com/23seriy/kubernetes-1.36-in-action.git
cd kubernetes-1.36-in-action
```

### Prerequisites

- **macOS**
- **Docker Desktop** running
- **Homebrew** installed
- ~8 GB RAM available for Minikube
- Minikube should run **Kubernetes 1.36** for the current examples

### Step 1: Install Tools

```bash
chmod +x scripts/*.sh
./scripts/01-install-prerequisites.sh
```

This installs or verifies `minikube`, `kubectl`, `helm`, and `docker`.

### Step 2: Start Cluster

```bash
./scripts/02-start-cluster.sh
```

This creates a Minikube profile called `k8s136-in-action` on **Kubernetes `v1.36.0`** and enables the `metrics-server` addon (used by the HPA demo).

### Step 3: Deploy the Demo

```bash
./scripts/03-deploy-app.sh
```

This deploys the complete multi-feature demo application showcasing all K8s 1.36 capabilities.

### Step 4: Access the Demo

In a separate terminal:

```bash
kubectl port-forward svc/demo-app-service 8080:80 -n k8s136-demo
```

Then open: http://localhost:8080

### Step 5: Run Guided Scenarios

```bash
./scripts/04-demo-scenarios.sh
```

## 🎮 Demo Scenarios

The demo includes **9 guided scenarios** covering all major feature areas:

| # | Scenario | Maturity | What You'll See |
|---|---|---|---|
| 1 | **User Namespaces** | Stable | `hostUsers: false` — root inside, unprivileged on host |
| 2 | **MutatingAdmissionPolicy** | Stable | CEL auto-injects labels at admission — no webhook |
| 3 | **Fine-grained Kubelet Authorization** | Stable | Scoped service account with limited kubelet access |
| 4 | **Volume Group Snapshots** | Stable | Crash-consistent multi-PVC snapshots via CSI |
| 5 | **Resource Health Status** | Beta | Hardware health visible in `kubectl describe pod` |
| 6 | **Workload Aware Scheduling** | Alpha | Workload + PodGroup v1alpha2 gang scheduling |
| 7 | **HPA Scale to Zero** | Alpha | HPA scales deployment to zero replicas when idle |
| 8 | **Multi-feature Integration** | — | All features working together in a single app |
| 9 | **Feature Verification** | — | Automated diagnostics and manual verification commands |

## 🔍 How the Demo Works

- **User Namespaces** — dedicated pod runs with `hostUsers: false` (requires containerd 2.x + kernel 5.12+)
- **MutatingAdmissionPolicy** — CEL policy auto-injects labels on pod creation
- **Fine-grained authz** service account demonstrates least-privilege kubelet access
- **Multi-PVC setup** (data + logs) enables volume group snapshot testing
- **ImageVolume** pod mounts an OCI artifact directly as a read-only volume
- **HPA** defaults to `minReplicas: 1`; see `demo-hpa.yaml` comments for scale-to-zero setup
- **Workload + PodGroup v1alpha2** manifests demonstrate gang scheduling primitives
- **NetworkPolicy + ResourceQuota** show security best practices
- **Feature-specific directories** contain standalone examples for deeper exploration

## 📁 Project Structure

```text
kubernetes-1.36-in-action/
├── k8s/                                # Kubernetes manifests (deploy target)
│   ├── namespace.yaml
│   ├── demo-app.yaml                  # Multi-container Deployment
│   ├── demo-app-service.yaml
│   ├── demo-configmap.yaml            # Demo landing page
│   ├── demo-hpa.yaml                  # HPA (scale-to-zero instructions inside)
│   ├── demo-monitoring-sa.yaml
│   ├── demo-monitoring-pod.yaml       # Fine-grained authz test pod
│   ├── demo-pvcs.yaml                 # Multi-PVC for group snapshots
│   ├── demo-network-policy.yaml
│   ├── demo-resource-quota.yaml
│   ├── fine-grained-authz-policy.yaml # KubeletAuthorizationPolicy
│   ├── image-volume-pod.yaml          # OCI artifact as volume (GA)
│   ├── mutating-admission-policy.yaml # CEL-based mutation (GA)
│   ├── podgroup.yaml                  # Workload + PodGroup v1alpha2 for WAS
│   ├── user-namespaces-pod.yaml       # User Namespaces demo (GA)
│   └── volume-group-snapshot.yaml     # VolumeGroupSnapshot + class
├── stable-features/                    # Production-ready (GA) deep-dives
│   ├── fine-grained-authz/README.md
│   └── volume-group-snapshots/README.md
├── beta-features/                      # Beta feature deep-dives
│   └── resource-health-status/README.md
├── alpha-features/                     # Alpha feature deep-dives
│   └── workload-aware-scheduling/README.md
├── deployment-examples/
│   └── complete-k8s136-demo.yaml      # All-in-one integration reference
├── scripts/
│   ├── 01-install-prerequisites.sh
│   ├── 02-start-cluster.sh
│   ├── 03-deploy-app.sh
│   ├── 04-demo-scenarios.sh
│   └── 05-teardown.sh
```

## 🧹 Teardown

```bash
./scripts/05-teardown.sh
```

This deletes the namespace, removes the Minikube profile, and cleans up kubectl contexts.

## 💡 Key Takeaways

1. **User Namespaces is a one-line security upgrade** — `hostUsers: false` eliminates container escape risks
2. **MutatingAdmissionPolicy replaces webhooks** — CEL-based mutation without the TLS/availability drama
3. **Stable features are production-ready** — Fine-grained authz, DRA, group snapshots, and SELinux mounts solve real problems today
4. **Beta features are safe to test** — Resource health status and memory QoS improve operations without risk
5. **WAS is the future of distributed scheduling** — topology-aware gang scheduling with a clean Workload + PodGroup API
6. **Plan your Ingress NGINX migration** — the project is retired with no more security patches
7. **Feature gates matter** — Most beta/alpha features require explicit enablement

## 📚 Resources

- [Kubernetes v1.36 Release Notes](https://kubernetes.io/blog/2026/04/22/kubernetes-v1-36-release/)
- [Workload-Aware Scheduling Deep Dive](https://kubernetes.io/blog/2026/05/13/kubernetes-v1-36-advancing-workload-aware-scheduling/)
- [User Namespaces GA Announcement](https://kubernetes.io/blog/2026/04/23/kubernetes-v1-36-userns-ga/)
- [KEP Tracker](https://kep.k8s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [CSI Group Snapshot Documentation](https://kubernetes-csi.github.io/docs/group-snapshot-restore-feature.html)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

> **Note:** The project targets Kubernetes 1.36 in Minikube (configurable in `02-start-cluster.sh`). Beta/alpha features require feature gate enablement; volume group snapshots require a compatible CSI driver.

## 📝 License

MIT — Use freely for learning, demos, and presentations.
