# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `CONTRIBUTING.md` — contribution guidelines and development workflow
- `SECURITY.md` — security policy and responsible disclosure process
- `TESTING.md` — testing guide with automated and manual feature tests
- `TROUBLESHOOTING.md` — troubleshooting guide for common issues
- `CODE_OF_CONDUCT.md` — Contributor Covenant code of conduct
- `CHANGELOG.md` — this changelog
- `.shellcheckrc` — shellcheck configuration
- `.markdownlint.json` — markdown linting configuration
- `.github/workflows/validate.yml` — CI validation workflow (shellcheck, yamllint, bash -n, docs-check, markdownlint)
- `.github/ISSUE_TEMPLATE/` — bug report and feature request templates
- `.github/PULL_REQUEST_TEMPLATE.md` — PR template
- `.github/GOVERNANCE.md` — project governance document
- `.github/dependabot.yml` — automated GitHub Actions updates
- `scripts/lib/common.sh` — shared shell helpers (colors, info/warn/error) sourced by all numbered scripts
- Pod Security Standards (`restricted` profile) `securityContext` on demo pods

### Changed

- Synced `CLAUDE.md` and `README.md` with the actual profile name (`k8s136-in-action`) and namespace (`k8s136-demo`)
- Pinned container image tags (no more bare `:latest` / mutable refs)
- Replaced deprecated `kubectl version --short` with `kubectl version --client` in scripts
- Removed Python 3 dependency from `01-install-prerequisites.sh`
- Removed duplicate namespace creation in `03-deploy-app.sh`
- Removed dead post-namespace-delete CRD cleanup from `05-teardown.sh`
- Tightened `k8s/demo-network-policy.yaml` to match the actual demo (no ingress-nginx required)

### Fixed

- `k8s/mutating-admission-policy.yaml` — removed invalid `validationActions` field from `MutatingAdmissionPolicyBinding` (that field only exists on `ValidatingAdmissionPolicyBinding`)

### Removed

- `deployment-examples/complete-k8s136-demo.yaml` — superseded by per-feature manifests in `k8s/`

## [0.1.0] — 2026-05-25

### Added

- Initial release with K8s 1.36 feature demos
- Stable: User Namespaces, MutatingAdmissionPolicy, fine-grained kubelet authz, Volume Group Snapshots, ImageVolume
- Beta: Resource Health Status
- Alpha: Workload Aware Scheduling, HPA Scale to Zero
- Guided demo scenario script (`04-demo-scenarios.sh`)
- Complete Minikube setup and teardown scripts
- Published Medium article walkthrough
