# Fine-grained Kubelet API Authorization (Stable)

## Overview

Kubernetes 1.36 graduates fine-grained kubelet API authorization to General Availability (GA). This feature replaces the overly broad `nodes/proxy` permission with precise, least-privilege access control over the kubelet's HTTPS API.

## 🎯 Key Benefits

- **Security**: Eliminates need for broad `nodes/proxy` permissions
- **Compliance**: Enables least-privilege access for monitoring tools
- **Granularity**: Fine-grained control over specific kubelet endpoints
- **Audit**: Better visibility into API access patterns

## 📋 Prerequisites

- Kubernetes v1.36+ cluster
- KubeletFineGrainedAuthz feature gate (enabled by default in v1.36)
- RBAC permissions to create authorization policies

## 🚀 Quick Start

### 1. Create a Monitoring Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitoring-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-kubelet-reader
rules:
- apiGroups: [""]
  resources: ["nodes/proxy"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-kubelet-binding
subjects:
- kind: ServiceAccount
  name: monitoring-sa
  namespace: default
roleRef:
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
  name: monitoring-kubelet-reader
```

### 2. Configure Kubelet Fine-grained Authorization

Create a kubelet configuration file:

```yaml
# kubelet-config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
featureGates:
  KubeletFineGrainedAuthz: true
```

### 3. Create Fine-grained Authorization Policy

```yaml
# kubelet-authz-policy.yaml
apiVersion: node.k8s.io/v1
kind: KubeletAuthorizationPolicy
metadata:
  name: monitoring-policy
spec:
  # Allow monitoring service to access specific endpoints
  rules:
  - subjects:
    - kind: ServiceAccount
      name: monitoring-sa
      namespace: default
    resourceRules:
    - apiGroups: [""]
      resources: ["nodes/proxy"]
      verbs: ["get"]
      resourceNames: ["metrics", "healthz", "pods"]
    nonResourceRules:
    - nonResourceURLs: ["/metrics", "/healthz", "/pods"]
      verbs: ["get"]
```

## 📊 Example Use Cases

### Monitoring Tools Access

```yaml
# Prometheus monitoring access
apiVersion: node.k8s.io/v1
kind: KubeletAuthorizationPolicy
metadata:
  name: prometheus-monitoring
spec:
  rules:
  - subjects:
    - kind: ServiceAccount
      name: prometheus
      namespace: monitoring
    nonResourceRules:
    - nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
      verbs: ["get"]
```

### Health Check Access

```yaml
# Health check service access
apiVersion: node.k8s.io/v1
kind: KubeletAuthorizationPolicy
metadata:
  name: health-checker
spec:
  rules:
  - subjects:
    - kind: ServiceAccount
      name: health-checker
      namespace: kube-system
    nonResourceRules:
    - nonResourceURLs: ["/healthz", "/healthz/log", "/healthz/ping"]
      verbs: ["get"]
```

## 🔍 Verification

### 1. Test Access with Monitoring Service Account

```bash
# Create a test pod with monitoring service account
kubectl run test-monitoring --image=curlimages/curl \
  --serviceaccount=monitoring-sa --rm -it --restart=Never -- \
  curl -k https://kubernetes.default.svc:10250/metrics

# Test access to denied endpoint
kubectl run test-monitoring --image=curlimages/curl \
  --serviceaccount=monitoring-sa --rm -it --restart=Never -- \
  curl -k https://kubernetes.default.svc:10250/exec
```

### 2. Check Authorization Logs

```bash
# Check kubelet logs for authorization decisions
kubectl logs -n kube-system kubelet-$(hostname) | grep authorization

# Monitor RBAC events
kubectl get events --field-selector involvedObject.kind=KubeletAuthorizationPolicy
```

## 📈 Migration Guide

### From nodes/proxy to Fine-grained Access

**Before (v1.35 and earlier):**
```yaml
rules:
- apiGroups: [""]
  resources: ["nodes/proxy"]
  verbs: ["get", "list", "watch"]
```

**After (v1.36):**
```yaml
# No longer need nodes/proxy permission
# Use specific KubeletAuthorizationPolicy instead
apiVersion: node.k8s.io/v1
kind: KubeletAuthorizationPolicy
metadata:
  name: specific-access
spec:
  rules:
  - subjects:
    - kind: ServiceAccount
      name: monitoring-sa
    nonResourceRules:
    - nonResourceURLs: ["/metrics"]
      verbs: ["get"]
```

## ⚠️ Important Notes

- Feature is enabled by default in v1.36
- Existing `nodes/proxy` permissions still work but are deprecated
- Requires kubelet restart to apply configuration changes
- Authorization policies are evaluated before RBAC

## 🛠️ Troubleshooting

### Common Issues

1. **Access Denied Errors**
   ```bash
   # Check if policy exists and is correctly applied
   kubectl get kubeletauthorizationpolicies
   kubectl describe kubeletauthorizationpolicy <policy-name>
   ```

2. **Kubelet Configuration Issues**
   ```bash
   # Verify kubelet configuration
   ps aux | grep kubelet | grep config
   ```

3. **ServiceAccount Not Recognized**
   ```bash
   # Verify service account exists
   kubectl get serviceaccount <sa-name> -n <namespace>
   ```

## 📚 Additional Resources

- [KEP #2862: Fine-grained kubelet authorization](https://kep.k8s.io/2862)
- [Kubernetes Documentation: Kubelet Authentication/Authorization](https://kubernetes.io/docs/reference/access-authn-authz/kubelet-authz-authn/)
- [Node API Reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#node-v1-core)

---

**This feature significantly improves Kubernetes security posture by implementing the principle of least privilege for kubelet API access.**
