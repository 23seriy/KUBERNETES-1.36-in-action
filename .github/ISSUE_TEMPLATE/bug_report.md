---
name: Bug Report
about: Report something that isn't working as expected
title: "[BUG] "
labels: bug
assignees: ''

---

## Description

<!-- A clear and concise description of what the bug is -->

## Steps to Reproduce

<!-- Exact steps to reproduce the behavior -->

1. Run `...`
2. Apply `...`
3. Observe `...`

## Expected Behavior

<!-- What should happen? -->

## Actual Behavior

<!-- What actually happens? -->

## Environment

- **OS**: <!-- e.g., macOS 14.0 -->
- **Minikube Version**: <!-- output of `minikube version` -->
- **Kubernetes Version**: <!-- output of `kubectl version --client` -->
- **Container Runtime**: <!-- docker / containerd / crio -->
- **Feature Gates**: <!-- any non-default gates enabled? -->

## Error Messages or Logs

<!-- Paste any error messages or relevant log output -->

```text
Paste logs here
```

## Diagnostics

<!-- Run these commands and share the output if applicable -->

```bash
minikube status -p k8s136-in-action
kubectl get pods -n k8s136-demo
kubectl get events -n k8s136-demo --sort-by=.metadata.creationTimestamp | tail -n 30
kubectl get crd | grep -E '(snapshot|scheduling|node|admission)'
```

## Additional Context

<!-- Any other context that might help us debug this? -->
