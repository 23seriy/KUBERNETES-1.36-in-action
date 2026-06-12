# Security Policy

## Scope

**Kubernetes 1.36 in Action** is an educational project designed to run locally on Minikube. It is **not intended for production use**. The security considerations here focus on safe learning practices and on accurately demonstrating the security-relevant features in Kubernetes 1.36.

## Reporting a Vulnerability

If you discover a security issue:

1. **Do NOT open a public issue**
2. **Email** [sergei.olshanetski@gmail.com](mailto:sergei.olshanetski@gmail.com) with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
3. You will receive acknowledgment within **48 hours**
4. A fix will be prioritized based on severity

## What Counts as a Vulnerability

| Category | Example |
|---|---|
| **Credentials in code** | Hardcoded passwords, API keys, tokens |
| **Unsafe defaults** | Services exposed beyond localhost without warning |
| **Container issues** | Running as root unnecessarily, outdated base images |
| **Script issues** | Commands that could damage the host system |
| **Misleading demos** | Manifests that claim to use a security feature but actually don't |

## Security Best Practices — Demo Context

This project is a **local Minikube demo**. The pods and policies are written to:

- Showcase the K8s 1.36 security features (User Namespaces, fine-grained kubelet authz, MutatingAdmissionPolicy, NetworkPolicy)
- Apply Pod Security Standards (`restricted` profile) where the demonstrated feature allows it
- Pin container image tags (avoid `:latest`) so demo behavior is reproducible

### If Adapting for Production

If you use these patterns beyond a local demo, you **must**:

1. Enable RBAC with least-privilege roles
2. Use Kubernetes Secrets (or an external secret manager) for all credentials
3. Use NetworkPolicies tailored to your actual ingress source (not the demo's)
4. Enable TLS for all service communication
5. Use non-root containers with `seccompProfile: RuntimeDefault` and `readOnlyRootFilesystem: true`
6. Scan images regularly for CVEs and pin to digests
7. Keep your cluster patched — alpha/beta feature gates may change between minor versions

## Known Demo Simplifications

| Item | Status | Notes |
|---|---|---|
| ImageVolume uses `busybox` | By design | Real OCI artifact volumes typically reference signed model/data images |
| User Namespaces requires runtime support | Documented | Minikube's Docker driver does not support `hostUsers: false` |
| MutatingAdmissionPolicy is namespace-scoped via label | By design | The policy only affects the `k8s136-demo` namespace |
| Volume Group Snapshots require CSI driver | Documented | Hostpath CSI driver in Minikube is for demo only |

## Supported Versions

| Version | Supported |
|---|---|
| Latest `main` | Yes |
| Older releases | Best effort |

---

Security questions? Email [sergei.olshanetski@gmail.com](mailto:sergei.olshanetski@gmail.com) 🌸
