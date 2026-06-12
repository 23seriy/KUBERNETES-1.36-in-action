## Description

<!-- Provide a clear description of what this PR does -->

Closes #<!-- Issue number if applicable -->

## Type of Change

- [ ] 🐛 Bug fix
- [ ] ✨ New feature demo
- [ ] 📚 Documentation update
- [ ] ♻️ Refactoring (no behavior change)
- [ ] 🔧 CI/CD or tooling change

## What Changed?

<!-- Describe the changes in detail -->

## Testing

- [ ] Tested locally by running `./scripts/03-deploy-app.sh` and `./scripts/04-demo-scenarios.sh`
- [ ] Tested on Kubernetes 1.36 (Minikube profile `k8s136-in-action`)
- [ ] All scripts pass `shellcheck -x scripts/*.sh`
- [ ] All YAML passes `yamllint -d relaxed k8s/*.yaml`
- [ ] New manifests validated with `kubectl apply --dry-run=client`
- [ ] No regressions observed in other scenarios

## Checklist

- [ ] Code follows the project's style (scripts use `set -euo pipefail`, source `scripts/lib/common.sh`)
- [ ] Container image tags are pinned (no bare `:latest`)
- [ ] Documentation is updated (README, CLAUDE.md, TROUBLESHOOTING, CHANGELOG)
- [ ] No secrets or credentials were added
- [ ] Commit messages follow conventions: `[type] description`
- [ ] I have reviewed the [Contributing Guidelines](../CONTRIBUTING.md)

## Feature(s) Affected

<!-- Which K8s 1.36 feature(s) does this PR touch? -->

- Feature: <!-- e.g., User Namespaces (Stable) -->
- Manifests: <!-- e.g., k8s/user-namespaces-pod.yaml -->

## Demo Output

<!-- If applicable, paste demo output or screenshots showing the change works -->

---

Thank you for contributing! 🌸
