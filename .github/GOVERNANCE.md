# Project Governance

## Overview

Kubernetes 1.36 in Action is a community-driven educational project demonstrating the features in the K8s 1.36 "ハル (Haru)" release. This document outlines how we make decisions, manage contributions, and maintain the project.

## Project Goals

1. **Educate** — Provide clear, hands-on examples of K8s 1.36 features at every maturity level
2. **Demonstrate** — Show feature gates, CRDs, and policies that users can adapt
3. **Empower** — Enable users to test new K8s features locally without a production cluster
4. **Maintain Quality** — Keep manifests, scripts, and docs accurate as K8s evolves

## Maintainers

The project is maintained by:

- **Sergei Olshanetski** (@23seriy) — Creator and primary maintainer

Maintainers handle:

- Reviewing pull requests
- Merging approved changes
- Managing releases
- Setting project direction
- Enforcing code standards

## Contributing

We welcome contributions! See [CONTRIBUTING.md](../CONTRIBUTING.md) for:

- How to get started
- Development workflow
- Testing requirements
- PR conventions

## Decision Making

### Minor Changes (Docs, Bug Fixes, Manifest Cleanups)

- Open a PR with a clear description
- At least one maintainer approval needed
- CI checks must pass
- No formal review period required

### Major Changes (New Demos, Restructuring)

- Open an issue or discussion first
- Describe the change and motivation
- Get feedback from maintainers
- Then open a PR
- Allow 3–5 days for community feedback
- At least one maintainer approval needed

### Breaking Changes

- Only in major version bumps
- Clearly documented in CHANGELOG
- At least one maintainer approval
- Community discussion encouraged

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** — Breaking changes (Kubernetes minor-version bump, script incompatibility)
- **MINOR** — New feature demos
- **PATCH** — Bug fixes (script fixes, doc corrections)

### Release Steps

1. Update [CHANGELOG.md](../CHANGELOG.md) with all changes
2. Create a git tag: `git tag v1.2.3`
3. Push tag: `git push origin v1.2.3`
4. Announce on relevant channels

## Conflict Resolution

If there's disagreement on a change:

1. **Discussion** — Comment on the PR with your perspective
2. **Compromise** — Find middle ground where possible
3. **Escalation** — Maintainer makes the final call if needed
4. **Respect** — Follow the decision, even if you disagree

## Code Standards

All contributions must:

- Pass `shellcheck` (shell scripts)
- Pass `yamllint -d relaxed` (YAML files)
- Pin container image tags (no bare `:latest`)
- Update documentation if behavior changes
- Include clear commit messages: `[type] description`

See [.github/workflows/validate.yml](workflows/validate.yml) for all automated checks.

## Community Channels

- **Issues** — Bug reports, feature requests, questions
- **Discussions** — General conversations, ideas, feedback
- **Pull Requests** — Code review and collaboration

## Code of Conduct

All participants must follow the [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md). We're committed to providing a respectful, inclusive environment.

## Licensing

All contributions are licensed under [MIT](../LICENSE). By submitting a PR, you agree to this license.

---

Questions about governance? Open an issue or discussion! 🌸
