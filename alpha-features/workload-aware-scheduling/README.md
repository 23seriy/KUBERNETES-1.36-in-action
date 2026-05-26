# Workload Aware Scheduling (WAS) - Alpha

## Overview

Kubernetes 1.36 introduces a **significant architectural evolution** for Workload Aware Scheduling in the `scheduling.k8s.io/v1alpha2` API group. The key change: the **Workload** API now serves as a static template, while the new **PodGroup** API handles runtime state. This separation improves scalability and paves the way for topology-aware scheduling, workload-aware preemption, and DRA integration.

> **Note:** The `v1alpha1` API from 1.35 has been completely replaced by `v1alpha2`. Update your manifests accordingly.

## 🎯 Key Features in 1.36

- **Workload + PodGroup API split**: Static template vs runtime state separation
- **Gang scheduling**: Atomic all-or-nothing scheduling via the PodGroup scheduling cycle
- **Topology-aware scheduling**: Co-locate pods within specific physical/logical domains (rack, zone)
- **Workload-aware preemption**: Preempt across multiple nodes simultaneously for group placement
- **DRA ResourceClaim support**: PodGroups share ResourceClaims, bypassing the 256-item limit
- **Job controller integration**: Automatic Workload + PodGroup creation for Jobs

## 📋 Prerequisites

- Kubernetes v1.36+ cluster
- `WorkloadAwareScheduling` feature gate enabled
- `WorkloadWithJob` feature gate enabled (for Job integration)
- Cluster admin permissions

## 🚀 Quick Start

### 1. Enable Feature Gates

```bash
# Enable via kube-apiserver and kube-scheduler flags
--feature-gates=WorkloadAwareScheduling=true,WorkloadWithJob=true
```

### 2. Create a Workload (Static Template)

```yaml
# The Workload defines the pod group structure as a template.
# Controllers (like the Job controller) stamp out PodGroups from it.
apiVersion: scheduling.k8s.io/v1alpha2
kind: Workload
metadata:
  name: training-job-workload
  namespace: ml-workloads
spec:
  podGroupTemplates:
  - name: workers
    schedulingPolicy:
      gang:
        minCount: 4  # All 4 must be schedulable or none are bound
```

### 3. Create a PodGroup (Runtime Object)

```yaml
# The PodGroup manages runtime scheduling state.
# It references the Workload template it originated from.
apiVersion: scheduling.k8s.io/v1alpha2
kind: PodGroup
metadata:
  name: training-job-workers-pg
  namespace: ml-workloads
spec:
  podGroupTemplateRef:
    workload:
      workloadName: training-job-workload
      podGroupTemplateName: workers
  schedulingPolicy:
    gang:
      minCount: 4
status:
  conditions:
  - type: PodGroupScheduled
    status: "True"
```

### 4. Link Pods to the PodGroup

```yaml
# Pods use the new schedulingGroup field (replaces the old workloadRef)
apiVersion: v1
kind: Pod
metadata:
  name: worker-0
  namespace: ml-workloads
spec:
  schedulingGroup:
    podGroupName: training-job-workers-pg
  containers:
  - name: trainer
    image: pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime
    resources:
      requests:
        nvidia.com/gpu: 1
        memory: "8Gi"
        cpu: "2"
```

## 📊 Advanced Examples

### Topology-Aware Gang Scheduling

Co-locate pods within the same rack to minimize network latency for distributed training:

```yaml
apiVersion: scheduling.k8s.io/v1alpha2
kind: PodGroup
metadata:
  name: topology-aware-workers-pg
  namespace: ml-workloads
spec:
  schedulingPolicy:
    gang:
      minCount: 4
    # Enforce rack-level co-location
    schedulingConstraints:
      topology:
      - key: topology.kubernetes.io/rack
```

The scheduler generates candidate placements (subsets of nodes per rack), evaluates feasibility, and scores to select the best fit.

### Workload-Aware Preemption

The PodGroup is treated as a single preemptor unit. Use `priority` and `disruptionMode` to control eviction behavior:

```yaml
apiVersion: scheduling.k8s.io/v1alpha2
kind: PodGroup
metadata:
  name: high-priority-training-pg
  namespace: ml-workloads
spec:
  priorityClassName: high-priority
  priority: 1000  # Overrides individual pod priorities
  disruptionMode: PodGroup  # All-or-nothing eviction
  schedulingPolicy:
    gang:
      minCount: 8
```

When this PodGroup can't be scheduled, the scheduler preempts pods across multiple nodes simultaneously to make room for the entire group.

### DRA ResourceClaim Sharing

PodGroups can share ResourceClaims, enabling massive workloads to share GPU devices:

```yaml
apiVersion: scheduling.k8s.io/v1alpha2
kind: PodGroup
metadata:
  name: shared-gpu-workers-pg
  namespace: ml-workloads
spec:
  resourceClaims:
  - name: shared-gpu
    resourceClaimTemplateName: gpu-claim-template
  schedulingPolicy:
    gang:
      minCount: 4
---
# Each pod references the same claim — resolved to the PodGroup-level ResourceClaim
apiVersion: v1
kind: Pod
metadata:
  name: gpu-worker-0
  namespace: ml-workloads
spec:
  schedulingGroup:
    podGroupName: shared-gpu-workers-pg
  resourceClaims:
  - name: shared-gpu
    resourceClaimTemplateName: gpu-claim-template
  containers:
  - name: trainer
    image: pytorch/pytorch:latest
    resources:
      claims:
      - name: shared-gpu
```

A single PodGroup reference in `status.reservedFor` can represent many more than 256 pods.

### Job Controller Integration

With the `WorkloadWithJob` feature gate, the Job controller automatically creates Workload + PodGroup objects:

```yaml
# Just create a normal Job — the controller handles WAS wiring
apiVersion: batch/v1
kind: Job
metadata:
  name: distributed-training
  namespace: ml-workloads
spec:
  parallelism: 4
  completions: 4
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: trainer
        image: pytorch/pytorch:latest
        resources:
          requests:
            nvidia.com/gpu: 1
            memory: "8Gi"
            cpu: "2"
```

The Job controller automatically:
1. Creates a Workload and a corresponding runtime PodGroup
2. Sets `.spec.schedulingGroup` onto every Pod the Job creates
3. Sets the Job as the owner (garbage-collected when the Job is deleted)

## 🔍 How the PodGroup Scheduling Cycle Works

1. **Snapshot**: The scheduler takes a single snapshot of the cluster state (no race conditions)
2. **Evaluate**: It finds valid node placements for all pods using the standard filtering + scoring phases
3. **Decision**: Applied atomically for the entire PodGroup:
   - **Success**: All schedulable pods are bound together; remaining pods wait in the queue
   - **Failure**: None are bound; all return to the queue with a backoff period

Already-scheduled pods are never evicted by subsequent scheduling cycles.

## � Verification and Monitoring

```bash
# List all PodGroups and Workloads
kubectl get podgroups -A
kubectl get workloads -A

# Check PodGroup scheduling status
kubectl describe podgroup training-job-workers-pg -n ml-workloads

# Check scheduler events
kubectl get events --field-selector involvedObject.kind=PodGroup

# View scheduler logs for PodGroup decisions
kubectl logs -n kube-system -l component=kube-scheduler | grep -i podgroup
```

## ⚠️ Important Notes

- **Alpha Feature**: The `v1alpha2` API replaced `v1alpha1` in this release and may continue to evolve
- **No custom scheduler needed**: WAS is built into `kube-scheduler` (no `schedulerName` override required)
- **Topology-aware scheduling** does not yet trigger preemption to satisfy constraints (planned for 1.37)
- **Pods already on nodes stay running** — the scheduler will not evict them even if the group fails subsequent cycles

## 🛠️ Troubleshooting

1. **PodGroup stuck in PreEnqueue**
   ```bash
   # The scheduler holds pods until minCount is met
   kubectl describe podgroup <group-name>
   # Check if enough pods exist to meet the gang requirement
   ```

2. **Group fails atomically (none scheduled)**
   ```bash
   # Check cluster capacity — the group needs enough resources for ALL pods simultaneously
   kubectl describe nodes | grep -A 5 "Allocated resources"
   ```

3. **Stale v1alpha1 manifests**
   ```bash
   # v1alpha1 is gone in 1.36 — update to v1alpha2
   # Old: scheduling.x-k8s.io/v1alpha1 PodGroup
   # New: scheduling.k8s.io/v1alpha2 Workload + PodGroup
   ```

## 📚 Additional Resources

- [Official WAS Blog Post](https://kubernetes.io/blog/2026/05/13/kubernetes-v1-36-advancing-workload-aware-scheduling/)
- [KEP #4671: Workload Aware Scheduling](https://kep.k8s.io/4671)
- [KEP #5710: PodGroup API](https://kep.k8s.io/5710)

---

**Workload Aware Scheduling in 1.36 represents a generational shift from pod-by-pod scheduling to group-aware, topology-conscious, DRA-integrated workload management — built natively into kube-scheduler.**
