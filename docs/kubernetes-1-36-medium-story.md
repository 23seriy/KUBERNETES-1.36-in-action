# Kubernetes 1.36 "ハル (Haru)": The Future of Container Orchestration is Here

*Spring has arrived for Kubernetes with the release of version 1.36, codenamed "ハル (Haru)" — Japanese for spring. This release brings 70 enhancements that are blooming across the ecosystem, with 18 features graduating to Stable, 25 entering Beta, and 25 new Alpha features that promise to reshape how we think about container orchestration.*

> **TL;DR:** Kubernetes 1.36 ships 70 enhancements — User Namespaces and MutatingAdmissionPolicy finally reach GA after years of development, fine-grained kubelet authorization locks down node-level secrets, volume group snapshots and DRA go production-ready, and workload-aware scheduling (with a new Workload + PodGroup API split) advances gang scheduling in alpha. I built a [companion repo](https://github.com/23seriy/kubernetes-1.36-in-action) so you can try every feature on your laptop.

## 🌸 The Spring Release: What Makes K8s 1.36 Special?

Kubernetes 1.36 continues the tradition of delivering consistent, high-quality releases that underscore the strength of the development cycle and the vibrant community support. This release isn't just about incremental improvements — it's about foundational changes that address real-world production challenges.

### By the Numbers
- **70 total enhancements**
- **18 features graduating to Stable** (production-ready)
- **25 features entering Beta** (ready for testing)
- **25 new Alpha features** (experimental but promising)

## 🚀 Stable Features: Production-Ready Innovations

### 1. Fine-Grained Kubelet API Authorization: Security Revolution

For years, Kubernetes administrators faced a security dilemma: monitoring tools needed broad `nodes/proxy` permissions, creating potential security risks. Kubernetes 1.36 solves this with **fine-grained kubelet API authorization**.

**The Problem Before:**
```yaml
# Old way - overly permissive
rules:
- apiGroups: [""]
  resources: ["nodes/proxy"]
  verbs: ["get", "list", "watch"]  # Too broad!
```

**The Solution Now:**
```yaml
# New way - precise control
apiVersion: node.k8s.io/v1
kind: KubeletAuthorizationPolicy
metadata:
  name: monitoring-policy
spec:
  rules:
  - subjects:
    - kind: ServiceAccount
      name: prometheus
    nonResourceRules:
    - nonResourceURLs: ["/metrics", "/healthz"]
      verbs: ["get"]  # Only what's needed!
```

**Why This Matters:**
- **Security**: Eliminates unnecessary attack surfaces
- **Compliance**: Meets strict security requirements
- **Audit**: Better visibility into API access patterns

### 2. Volume Group Snapshots: Disaster Recovery Evolved

Multi-volume applications like databases, analytics platforms, and content management systems have long struggled with ensuring consistency across volumes. **Volume Group Snapshots** solve this by taking crash-consistent snapshots across multiple PersistentVolumeClaims simultaneously.

**Real-World Scenario:**
Imagine you're running a PostgreSQL database with separate volumes for data and logs. Traditional snapshots could capture the data volume at 2:00:00 PM and the log volume at 2:00:05 PM — creating an inconsistent state that could corrupt your database during recovery.

**With Volume Group Snapshots:**
```yaml
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshot
metadata:
  name: database-group-snapshot
spec:
  volumeGroupSnapshotClassName: csi-hostpath-group-snapclass
  source:
    selector:
      matchLabels:
        app: database  # All database volumes snap together!
```

**Use Cases This Enables:**
- **Database Clusters**: Consistent backup of multi-volume databases
- **Analytics Platforms**: Snapshot data + processing volumes together
- **Content Management**: Backup media + metadata volumes atomically

### 3. Dynamic Resource Allocation (DRA): GPU Clusters Reimagined

The rise of AI/ML workloads exposed limitations in Kubernetes' resource management. **Dynamic Resource Allocation** graduates to Stable, providing production-ready hardware resource management for GPU clusters and specialized hardware.

**What This Solves:**
- **GPU Sharing**: Multiple workloads sharing expensive GPU resources
- **Specialized Hardware**: FPGAs, TPUs, and other accelerators
- **Resource Pools**: Logical grouping of hardware resources

**Key DRA advancements in 1.36:**
- **AdminAccess (Stable)**: Cluster admins can grant privileged access to specific devices for debugging and monitoring
- **Prioritized Alternatives (Stable)**: Workloads can specify ordered fallback hardware — "give me an H100, or if unavailable, an A100, or a T4"
- **PodResources Extension (Stable)**: Monitoring tools can see what hardware a pod is actually using
- **GPU Sharing, Device Taints (Beta)**: Mark a device as "do not schedule" without removing it; partition-able devices for fine-grained sharing

### 4. User Namespaces: Nine Years in the Making, Finally GA

This might be the most impactful security feature in years. Before 1.36, a process running as root (UID 0) inside a container was also UID 0 on the host kernel. Container escapes exist — when they happen, UID 0 inside means UID 0 outside. That's not isolation; that's an open door.

**With User Namespaces**, the container process that thinks it's root maps to an unprivileged UID on the host. Breaking out of the container doesn't grant anything — the attacker lands as nobody. Literally.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: isolated-workload
spec:
  hostUsers: false  # ← This is the entire change
  containers:
  - name: app
    image: fedora:42
    securityContext:
      runAsUser: 0  # Root inside, nobody on the host
```

```bash
$ kubectl exec isolated-workload -- id
uid=0(root) gid=0(root) groups=0(root)
# But on the host, this process runs as an unprivileged UID in the high thousands
```

The road to GA wasn't just about the API — it required kernel-level work on **ID-mapped mounts** (Linux 5.12+) so volumes don't need recursive `chown` at startup. Instead, the kernel remaps ownership at mount time — an O(1) operation instead of walking every file.

**Why This Matters:**
- **Multi-tenant clusters**: Container escapes no longer grant host root
- **Compliance**: Meets strict isolation requirements without sacrificing functionality
- **Capabilities become namespaced**: `CAP_NET_ADMIN` grants power over container-local resources only

### 5. MutatingAdmissionPolicy: The End of Webhook Drama

For years, mutating resources — injecting labels, tweaking defaults, enforcing org-wide conventions — required running admission webhooks. And we all know how that story goes: webhook down → deployments stuck; cert expired → cluster-wide outage; latency spike → API server slowdown.

**MutatingAdmissionPolicy** is now GA and enabled by default. Write mutation rules as native Kubernetes objects using CEL expressions — no webhook server, no TLS ceremony, no 2am incidents.

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingAdmissionPolicy
metadata:
  name: label-injector
spec:
  reinvocationPolicy: Never
  matchConstraints:
    resourceRules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      operations: ["CREATE"]
      resources: ["pods"]
  mutations:
  - patchType: "ApplyConfiguration"
    applyConfiguration:
      expression: >
        Object{
          metadata: Object.metadata{
            labels: {"managed-by": "cel-policy"}
          }
        }
```

```bash
$ kubectl run test --image=nginx
$ kubectl get pod test -o jsonpath='{.metadata.labels}'
{"managed-by":"cel-policy"}  # Injected at admission — no webhook running
```

This works alongside `ValidatingAdmissionPolicy` (GA since 1.30) to give you a complete admissions framework that lives natively in the cluster. For the 80% of mutation needs that are straightforward, you can skip the entire webhook project.

### 6. ImageVolume: Mount OCI Artifacts Directly

You can now reference an OCI image as a volume and mount it directly into a container — no init container pattern needed. Useful for distributing ML model weights, config bundles, or read-only data artifacts alongside your workload.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: model-server
spec:
  containers:
  - name: inference
    image: my-inference-server:latest
    volumeMounts:
    - name: model-weights
      mountPath: /models
  volumes:
  - name: model-weights
    image:
      reference: registry.example.com/ml-models:v2.1
      pullPolicy: IfNotPresent  # Cached like container images
```

The OCI image filesystem mounts read-only. No sidecar. No init container. No build-time bloat.

### 7. Node Log Query: No More SSH

`kubectl get --raw /api/v1/nodes/<name>/proxy/logs/` now works cleanly, letting you retrieve node-level service logs through the Kubernetes API without SSHing into the node.

```bash
$ kubectl get --raw "/api/v1/nodes/my-node/proxy/logs/"
<a href="containers/">containers/</a>
<a href="pods/">pods/</a>
```

For security teams, this eliminates the need to explain — again — why you need SSH access to a production node at 11pm.

## 🔥 Beta Features: Ready for Production Testing

### 1. Resource Health Status: Hardware Monitoring Revolution

**The Problem**: Pod crashes due to hardware failures were notoriously difficult to diagnose. Was it the application? The network? Or faulty hardware?

**The Solution**: Native hardware health reporting directly visible in `kubectl describe pod`:

```bash
$ kubectl describe pod ml-training-xyz
...
Status:
  Allocated Resources:
    nvidia.com/gpu: 1
  Allocated Resources Status:
    nvidia.com/gpu:
      Name: nvidia.com/gpu
      Status: Unhealthy  # ← Hardware issue detected!
      Last HealthProbeTime: 2026-05-20T14:30:00Z
```

**Why This is Game-Changing:**
- **Faster Troubleshooting**: Immediate visibility into hardware issues
- **Automated Recovery**: Controllers can automatically respond to hardware failures
- **Cost Savings**: Quickly identify and replace faulty hardware

### 2. Mixed Version Proxy: Smoother Upgrades

During a control plane rolling upgrade, different API server instances might be on different Kubernetes versions. **Mixed Version Proxy** lets the old API server proxy requests for resources it doesn't recognize to a newer instance that does. Clients don't get 404s mid-upgrade.

```bash
# During a rolling upgrade, some API servers may be v1.35 while others are v1.36.
# Mixed Version Proxy ensures requests for newer API versions are forwarded
# to the upgraded API server that can serve them — transparently.
kubeadm upgrade apply v1.36.0   # upgrade first control-plane node
# remaining nodes still serve v1.35 traffic normally
```

### 3. Staleness Mitigation for Controllers

Kubernetes controllers sometimes act on stale cached data from the informer cache, which might be seconds or minutes behind the actual API server state. This adds mechanisms for controllers to detect staleness before acting — less flapping, more correct behavior during high churn.

### 4. kubectl .kuberc User Preferences

Your cluster connection config and personal preferences have always lived awkwardly in the same `kubeconfig` file. `.kuberc` splits them apart — default namespace, output format, aliases travel with you, not with the cluster config.

### 5. ComponentStatusz & ComponentFlagz

Every Kubernetes component now exposes `/statusz` (actual running version) and `/flagz` (actual startup flags). Configuration drift — where the config file says one thing and the running process started with something different — is now auditable without node access.

## 🌟 Alpha Features: Glimpsing the Future

### 1. Workload Aware Scheduling (WAS): The Architecture Evolution

Since Kubernetes v1.0, a single assumption has been baked into `kube-scheduler`: pods are the unit of scheduling. Each pod is an independent decision. That assumption breaks for AI/ML training, MPI jobs, and any distributed workload where partial deployment is worse than no deployment.

Kubernetes 1.36 introduces a **significant architectural evolution** in the `scheduling.k8s.io/v1alpha2` API group, cleanly separating concerns:

**Workload** — a static template defining your pod group structure:
```yaml
apiVersion: scheduling.k8s.io/v1alpha2
kind: Workload
metadata:
  name: training-job-workload
spec:
  podGroupTemplates:
  - name: workers
    schedulingPolicy:
      gang:
        minCount: 4  # All 4 must start together or none do
```

**PodGroup** — the runtime object holding actual scheduling state:
```yaml
apiVersion: scheduling.k8s.io/v1alpha2
kind: PodGroup
metadata:
  name: training-job-workers-pg
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

**Pods link to the PodGroup** via a new `schedulingGroup` field (replacing the old `workloadRef`):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: worker-0
spec:
  schedulingGroup:
    podGroupName: training-job-workers-pg
  containers:
  - name: trainer
    image: pytorch/pytorch:latest
    resources:
      requests:
        nvidia.com/gpu: 1
```

**What's new beyond the API split:**
- **Topology-aware scheduling**: Define topology constraints (rack, zone) directly on a PodGroup — the scheduler co-locates pods to minimize network latency
- **Workload-aware preemption**: The scheduler treats the entire PodGroup as a single preemptor unit, preempting across multiple nodes simultaneously
- **PodGroup priority & disruptionMode**: Override individual pod priorities and choose all-or-nothing eviction
- **DRA ResourceClaim support**: PodGroups can share ResourceClaims, enabling thousands of pods to share GPU devices without hitting the 256-item limit
- **Job controller integration**: Enable the `WorkloadWithJob` feature gate and the Job controller automatically creates Workload + PodGroup objects — no manual wiring needed

**Why This Matters:**
- **Resource Efficiency**: No more wasted resources from partial deployments and scheduling deadlocks
- **Performance**: Atomic scheduling decisions with cluster-wide snapshot prevent race conditions
- **Simplicity**: Replaces Volcano, Kueue coscheduling, and custom schedulers for many use cases

### 2. HPA Scale to Zero: Cost Optimization Revolution

The **Horizontal Pod Autoscaler** can now scale to zero for custom metrics, enabling true serverless behavior for stateless workloads.

**Use Cases:**
- **Event-Driven Applications**: Scale to zero when idle
- **Development Environments**: No-cost staging environments
- **Batch Processing**: Scale up only when work is available

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: event-processor-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: event-processor
  minReplicas: 0  # ← Scale to zero!
  maxReplicas: 100
  metrics:
  - type: External
    external:
      metric:
        name: queue_length
      target:
        type: AverageValue
        averageValue: "10"
```

## 📊 Performance and Reliability Improvements

### Memory QoS with cgroups v2

On cgroupv2 nodes, Kubernetes can now set `memory.min` and `memory.low` alongside `memory.max`:
- **`memory.min`**: Hard guarantee — the kernel will not reclaim this memory, ever
- **`memory.low`**: Soft preference — reclaim from this pod last

This gives you tiered memory protection so critical workloads don't get OOM-killed because a batch job decided to eat all available memory at 3am.

### SELinux Volume Labels: Smart Mounts

SELinux label management is now GA with a fundamentally smarter approach. Instead of recursively relabeling every file in a volume at pod startup (which blocked startup for volumes with thousands of files), Kubernetes mounts the volume directly with the correct SELinux context. No recursive walk. The mount carries the label. Pod startup for large volumes improves dramatically.

## 🔄 Important Deprecations and Removals

### 🚨 Ingress NGINX is Retired

This is the one thing in this release you need to act on. The `kubernetes/ingress-nginx` project was officially retired on March 24, 2026. No more security patches. No more maintenance. It will not be updated for Kubernetes 1.36 or beyond.

The recommended migration path is **Gateway API** (GA since October 2023). If you're on a managed service (GKE, EKS, AKS), check your provider's Gateway API support. If self-managed, Envoy Gateway, Traefik, and HAProxy Ingress Controller all support it natively.

Don't keep running unpatched ingress infrastructure. Ingress is internet-facing by definition.

### Service `.spec.externalIPs` Deprecated

`externalIPs` lets a Service respond on arbitrary external IPs. CVE-2020-8554 flagged it in 2020 as a traffic interception vector. In 1.36, it's formally deprecated with removal planned for v1.43. Alternatives: LoadBalancer Service, NodePort, or Gateway API.

### gitRepo Volume — Permanently Disabled

Deprecated in v1.11 (2018). It ran git commands as root, making it a privilege escalation risk. In v1.36, the plugin is permanently disabled and cannot be turned back on. The replacement is an init container that runs `git clone` with a proper security context.

## 🛠️ Getting Started with Kubernetes 1.36

### Upgrade Path

For most users, upgrading to 1.36 is straightforward:

```bash
# Upgrade control plane
kubeadm upgrade plan
kubeadm upgrade apply v1.36.0

# Upgrade nodes
kubeadm upgrade node

# Update kubelet
systemctl restart kubelet
```

### Enable Beta Features

```bash
# Enable feature gates for beta features
--feature-gates=ResourceHealthStatus=true,MixedVersionProxy=true,MemoryQoS=true
```

### Enable Alpha Features (for testing)

```bash
# Enable experimental features
--feature-gates=WorkloadAwareScheduling=true,HPAScaleToZero=true
```

## 🎯 What This Means for the Industry

### For Enterprise Users
- **Security**: User Namespaces eliminate container escape risks; fine-grained kubelet authorization locks down node secrets
- **Compliance**: MutatingAdmissionPolicy replaces fragile webhooks with auditable, native policy
- **Reliability**: Hardware health monitoring and staleness mitigation improve uptime
- **Cost**: Scale-to-zero and DRA prioritized alternatives reduce TCO

### For Platform Teams
- **Immediate action required**: Migrate off Ingress NGINX before security patches stop
- **Operational wins**: MutatingAdmissionPolicy GA eliminates webhook maintenance; `.kuberc` separates user prefs from cluster config
- **Observability**: ComponentStatusz, ComponentFlagz, and Node Log Query reduce SSH dependency

### For AI/ML Engineers
- **WAS with topology-aware scheduling**: Co-locate training pods on the same rack to minimize network latency
- **DRA with PodGroup ResourceClaims**: Share GPU devices across thousands of pods in a single workload
- **ImageVolume**: Distribute ML model weights as OCI artifacts without bloating container images

## 📝 What to Adopt (A Pragmatic Guide)

**Adopt now:**
- User Namespaces (`hostUsers: false`) — one-line change, massive security improvement
- MutatingAdmissionPolicy — port one webhook as a proof of concept
- Fine-grained kubelet authorization — GA and locked on, verify your CIS benchmark
- Plan your Ingress NGINX migration to Gateway API

**Adopt selectively:**
- DRA features for GPU-heavy clusters
- ImageVolume/OCI artifacts where build pipelines benefit
- Volume Group Snapshots for stateful multi-volume workloads

**Watch, don't rush:**
- WAS — the v1alpha2 API is still evolving (v1alpha1 was replaced this release)
- HPA scale-to-zero — metric source disappearance still requires careful handling
- DRA alpha features (Downward API, native CPU/memory as DRA resources)

## 🔮 Looking Ahead

Kubernetes 1.36 sets the stage for exciting developments:

1. **AI/ML Workloads**: WAS topology-aware scheduling + DRA PodGroup resource sharing make Kubernetes the premier platform for distributed training
2. **Security Maturity**: User Namespaces GA + MutatingAdmissionPolicy GA represent a generational security upgrade
3. **Webhook Sunset**: With both Validating and Mutating admission policies now GA in CEL, the era of maintaining webhook servers is ending
4. **Serverless**: Scale-to-zero HPA brings true serverless to native Kubernetes without KEDA for simple cases
5. **Edge & Upgrades**: Mixed-version proxy + ComponentStatusz/Flagz make operating diverse, distributed clusters practical

## 📚 Resources and Next Steps

- **[Official Release Notes](https://kubernetes.io/blog/2026/04/22/kubernetes-v1-36-release/)**
- **[Complete Examples Repository](https://github.com/23seriy/kubernetes-1.36-in-action)**
- **[Workload-Aware Scheduling Deep Dive](https://kubernetes.io/blog/2026/05/13/kubernetes-v1-36-advancing-workload-aware-scheduling/)** — official blog on WAS architecture
- **[User Namespaces GA Announcement](https://kubernetes.io/blog/2026/04/23/kubernetes-v1-36-userns-ga/)** — official blog on the nine-year journey to GA
- **[KEP Tracker](https://kep.k8s.io/)** for detailed feature specifications
- **[Kubernetes Documentation](https://kubernetes.io/docs/)** for implementation guides

## 🌸 Conclusion: Spring Has Sprung

Kubernetes 1.36 "ハル (Haru)" truly brings a spring awakening to container orchestration. With production-ready security improvements, revolutionary scheduling capabilities, and glimpses into a serverless future, this release addresses real-world challenges while paving the way for next-generation applications.

The combination of stable features you can use today, beta features ready for testing, and alpha features showing the future makes this release particularly compelling. Whether you're running enterprise workloads, developing cloud-native applications, or pushing the boundaries of distributed computing, Kubernetes 1.36 has something meaningful for you.

As the Kubernetes project continues its remarkable cadence of innovation, version 1.36 stands out as a release that not only solves today's problems but anticipates tomorrow's needs. The future of container orchestration is indeed here — and it's looking bright.

> 🔗 **Try it yourself:** Clone the [kubernetes-1.36-in-action](https://github.com/23seriy/kubernetes-1.36-in-action) repo and run all the examples on your laptop with Minikube.

---

*Have you tried Kubernetes 1.36 yet? Share your experiences with the new features in the comments below! And don't forget to follow for more deep dives into cloud-native technologies.*

#Kubernetes #CloudNative #DevOps #Containers #K8s #Tech #SoftwareEngineering #Microservices
