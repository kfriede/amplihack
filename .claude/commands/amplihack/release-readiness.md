---
name: release-readiness
version: 1.0.0
description: Multi-agent review → repair loop for release readiness
triggers:
  - "release readiness"
  - "release review"
  - "prepare release"
  - "ready to ship"
invokes:
  - type: skill
    name: release-readiness
dependencies:
  required:
    - skills/release-readiness/SKILL.md
    - amplifier-bundle/agents/specialized/release-reviewer.md
    - amplifier-bundle/agents/specialized/release-repair-worker.md
    - amplifier-bundle/context/RELEASE_READINESS.md
examples:
  - '/release-readiness "Prepare v2.0 for production deployment"'
  - '/release-readiness --branch release/v2.0 "Validate release candidate"'
  - '/release-readiness --slices slices.yaml "Review with pre-defined surfaces"'
---

# /release-readiness

Multi-agent review → repair loop that takes a codebase from "probably ready"
to "hands-off deployable."

## Usage

```
/release-readiness [--branch BRANCH] [--slices FILE] "description"
```

### Options

- `--branch BRANCH` — Target branch (default: current branch / main)
- `--slices FILE` — YAML file defining codebase surfaces (skips interactive slicing)
- `"description"` — What release you're preparing (e.g., "v2.0 production release")

### Slices File Format

```yaml
surfaces:
  - name: authentication
    description: User login, logout, session management, OAuth
    owns:
      - src/auth/
      - src/middleware/auth.py
      - tests/test_auth/
    smoke_test: "pytest tests/test_auth/ -x"

  - name: data-ingestion
    description: Syslog, API, and file-based data ingestion
    owns:
      - src/ingestion/
      - src/parsers/
    smoke_test: "pytest tests/test_ingestion/ -x"
```

## What It Does

1. Initializes SQL state (findings + cycles tables)
2. Slices the codebase into specialist surfaces
3. Runs the review → repair → re-review loop:
   - Dispatches parallel reviewer agents (one per slice, alternating model providers)
   - Aggregates findings, dedupes, triages
   - Creates git worktrees, dispatches repair workers
   - Merges fixes, validates, pushes
   - Repeats with a different model provider
4. Terminates on 2 consecutive empty cycles from different providers
5. Runs external verification (CI, smoke tests)
6. Produces a final summary

## Termination Criterion

The loop stops when **two consecutive review cycles produce zero findings**
AND those two cycles used **different model providers** (e.g., one Anthropic,
one OpenAI). This ensures blind spots from one provider family don't persist.

## See Also

- `amplifier-bundle/context/RELEASE_READINESS.md` — reference documentation
- `skills/release-readiness/SKILL.md` — full driver protocol
- `amplifier-bundle/agents/specialized/release-reviewer.md` — reviewer agent
- `amplifier-bundle/agents/specialized/release-repair-worker.md` — repair worker
