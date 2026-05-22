# Release Readiness

Reference documentation for the release-readiness workflow — a multi-agent
review → repair loop that validates a codebase is production-ready before
cutting a release tag.

## Overview

The release-readiness workflow dispatches parallel specialist reviewer agents
across codebase surfaces, aggregates findings into a SQL ledger, repairs issues
in isolated git worktrees, and repeats with alternating model providers until
two consecutive empty review cycles from different providers are achieved.

## When to Use

| Scenario | Use This? | Why |
|----------|-----------|-----|
| Preparing a release candidate | ✅ | Full codebase validation for hands-off deployment |
| Hands-off deployment (no human watching rollout) | ✅ | Undetected regressions are expensive |
| Codebase with many independent functional surfaces | ✅ | Review parallelizes well across specialists |
| Reviewing a specific PR | ❌ | Use normal code review or security-review |
| Heavy cross-cutting coupling that resists slicing | ❌ | Coordination overhead dominates |
| Quick quality check | ❌ | Use quality-audit instead |

## Relationship to Other Workflows

| Workflow | Scope | Termination | Use For |
|----------|-------|-------------|---------|
| **release-readiness** | Whole codebase by function | 2 consecutive empties, different providers | Release gates |
| **quality-audit** | Target path by category | Min 3, max 6 cycles | Code quality |
| **code-review** | PR diff | Single pass | Change review |
| **security-review** | PR diff or target | Single pass | Security audit |

## Codebase Slicing Guide

Slice by **user-facing function**, not by directory structure.

### Good Slices

- "User authentication" — login, logout, sessions, OAuth, password reset
- "Data ingestion" — syslog, API, file import, parsing, normalization
- "Job scheduling" — cron, task queue, retry logic, dead-letter handling
- "Deployment" — Helm charts, Docker Compose, init containers, health checks
- "Frontend dashboard" — React components, state management, API integration

### Bad Slices

- "src/services/" — too directory-oriented, doesn't map to user experience
- "utils" — cross-cutting, no clear ownership
- "everything" — too coarse to dogfood

### Sizing

- 8-12 slices for a focused single-service repo
- 15-25 slices for a multi-service repo (backend + frontend + infra)
- Each slice should be small enough that one reviewer can hold the full
  dependency graph in working memory and trace the user path end-to-end

### Boundary Ownership

When slices share files (e.g., Jobs → Scheduler → Ledger touch each other),
the **consumer** owns the fix and the producer is read-only context.

## Model Diversity

The core insight: different model families have different failure modes and
blind spots. Alternating providers between cycles means any single blind spot
has to survive two independently-biased passes.

| Provider | Recommended Model | Strength |
|----------|-------------------|----------|
| Anthropic | `claude-opus-4.7-high` | Deep semantic review — auth boundaries, invariants, subtle interaction bugs |
| OpenAI | `gpt-5.4` | Breadth and adversarial sweeps — enumeration, consistency, missing edge cases |

A finding that survives both providers is far less likely to be a false positive.
A clean cycle from a different provider is far stronger evidence of cleanliness
than two clean cycles from the same provider.

## Termination Logic

```
Two consecutive empties from DIFFERENT provider families → STOP
```

This is the most reliable termination criterion. One empty cycle is not enough —
the reviewer might share blind spots with the prior cycle's fixer. Two empties
from the SAME provider is weaker than two empties from different providers.

## Driver Checklist (Minimal)

```
[ ] Slice the repo (one-time)
[ ] Initialize findings + cycles SQL tables
[ ] Loop:
    [ ] git rev-parse HEAD → record as cycle start SHA
    [ ] Dispatch reviewers — model differs from prior cycle
    [ ] Aggregate strict-JSON findings into SQL
    [ ] If empty:
        [ ] empties += 1
        [ ] If empties >= 2 AND different providers: break
        [ ] Else: continue
    [ ] If non-empty:
        [ ] empties = 0
        [ ] For each finding cluster: create worktree, dispatch worker
        [ ] Wait for all workers
        [ ] Merge branches into main, resolve conflicts
        [ ] Run full validation suite
        [ ] Push main
        [ ] Update SQL findings to status=fixed
[ ] Confirm CI green on main
[ ] Smoke-test a fresh deploy
[ ] Write final summary
```

## Pitfalls

1. **Premature termination** — A cycle with 1 finding is not empty. Fix or accept-risk it.
2. **Same provider twice** — Two clean Opus cycles ≠ two independent clean cycles.
3. **Worker scope creep** — Pin workers to their assigned finding. New issues go to the next cycle.
4. **Driver self-fixing** — Use workers even for trivial fixes. Preserves audit trail and rubber-duck pass.
5. **Bootstrap auth deadlock** — Public endpoints getting auth dependencies added kills the login UX.
6. **Single-ingress trust boundaries** — If a field is server-only, ALL ingress points must strip it.
7. **External blockers as findings** — CI down for billing is not a code bug. Mark externally blocked.

## Entry Points

- **Command**: `/release-readiness [--branch BRANCH] [--slices FILE] "description"`
- **Skill auto-activation**: "release readiness", "prepare release", "ready to ship"
- **Direct**: `Skill(skill="release-readiness")`
