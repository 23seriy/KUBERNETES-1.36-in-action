# Contributing to Kubernetes 1.36 in Action

Thank you for your interest in improving this project! Whether you're fixing a bug, adding a new K8s 1.36 feature demo, or improving documentation, this guide will help you get started.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:

   ```bash
   git clone https://github.com/<your-user>/kubernetes-1.36-in-action.git
   cd kubernetes-1.36-in-action
   ```

3. **Create a branch** from `main`:

   ```bash
   git checkout -b feature/my-change
   ```

4. **Install prerequisites** — see [README.md](README.md) Quick Start.

## Development Workflow

### 1. Make Changes

- Edit scripts, YAML manifests, or documentation
- Keep changes focused — one logical change per PR

### 2. Test Locally

```bash
./scripts/02-start-cluster.sh
./scripts/03-deploy-app.sh
./scripts/04-demo-scenarios.sh
```

See [TESTING.md](TESTING.md) for the full testing guide.

### 3. Validate

```bash
# Lint shell scripts
shellcheck -x scripts/*.sh

# Lint YAML
yamllint -d relaxed k8s/*.yaml

# Lint Markdown
npx markdownlint-cli2 "**/*.md" --config .markdownlint.json
```

### 4. Commit and Push

```bash
git add .
git commit -m "[type] description of change"
git push origin feature/my-change
```

### 5. Open a Pull Request

- Use the PR template
- Reference any related issues
- Describe what changed and why

## Commit Message Conventions

Use the format `[type] description`:

| Prefix | Usage |
|---|---|
| `[feat]` | New feature or demo scenario |
| `[fix]` | Bug fix |
| `[docs]` | Documentation only |
| `[refactor]` | Code change with no behavior change |
| `[ci]` | CI/CD changes |
| `[deps]` | Dependency updates |
| `[improve]` | General improvement |

## Shell Script Standards

All scripts in `scripts/` must:

1. **Use** `#!/usr/bin/env bash` as the shebang
2. **Set** `set -euo pipefail` immediately after
3. **Pass** `shellcheck -x` with no errors
4. **Source** `scripts/lib/common.sh` for shared helpers (colors, info/warn/error)
5. **Include a header comment** describing what the script does

## YAML Manifest Standards

- All Kubernetes manifests must pass `yamllint -d relaxed`
- Use consistent indentation (2 spaces)
- Include comments for non-obvious settings, feature gates, or runtime requirements
- Pin image tags (no `:latest`) and prefer immutable tags or digests
- Apply Pod Security Standards (`restricted` profile) where the demo allows

## Feature Maturity Conventions

Organize demos by maturity:

- `stable-features/` — GA features in 1.36
- `beta-features/` — beta features (enabled by default)
- `alpha-features/` — alpha features (require explicit feature gate)

Each feature directory should contain a `README.md` explaining the feature, the manifests, and how to verify it works.

## Documentation Standards

When adding a feature or scenario:

1. Update `README.md` if the user-facing flow changes
2. Update `CLAUDE.md` if the project structure or conventions change
3. Add troubleshooting entries in `TROUBLESHOOTING.md` if relevant
4. Record the change in `CHANGELOG.md`

## Pull Request Process

1. Ensure CI checks pass
2. At least one maintainer approval is required
3. Squash commits if needed for a clean history
4. The maintainer will merge using the project's merge strategy

## Questions?

Open an issue or discussion — we're happy to help!

---

Thank you for contributing! 🌸
