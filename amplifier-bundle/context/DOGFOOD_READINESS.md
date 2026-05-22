# Dogfood Readiness

Reference documentation for the dogfood-readiness workflow — a multi-agent
browser-driven dogfood loop that validates a deployed web application is
production-ready by exercising it as real users would.

## Overview

The dogfood-readiness workflow dispatches parallel browser-driving agents
(via `agent-browser`) against a live deployed web application. Each agent
owns one slice of the app's user surface, exercises it systematically,
and captures evidence (screenshots, videos, server logs) for every issue
found. Findings are bucketed into fix lanes, repaired in isolated worktrees,
built into new images, deployed, and live-verified with before/after
screenshots.

## When to Use

| Scenario | Use This? | Why |
|----------|-----------|-----|
| Release candidate deployed, need UX validation | ✅ | Finds issues invisible to code review |
| Hands-off rollout where UX surprises are expensive | ✅ | Full user-surface coverage |
| App has many independent user-facing features | ✅ | Parallelizes well across specialists |
| No deployment exists yet | ❌ | Run release-readiness on code first |
| Testing one specific user flow | ❌ | Single QA scenario is cheaper |

## Relationship to Release-Readiness

These are complementary workflows forming a complete release gate:

```
Code Review Loop                Runtime Dogfood Loop
(release-readiness)             (dogfood-readiness)
       │                               │
       ▼                               ▼
 Reads source code              Drives live browser
 Finds: auth bugs,              Finds: state lies,
 injection, logic errors,       empty states, UX breaks,
 deploy config issues           500s, cache bugs,
       │                        timezone issues
       ▼                               │
 Fix + unit test                       ▼
       │                        Fix + build + deploy
       ▼                        + LIVE-VERIFY
 Deploy RC ──────────────────► Run dogfood on RC
                                       │
                                       ▼
                                Production release
```

## Slicing Guide

Slice by **user goal**, not by route or component.

### Tier System

| Tier | Agents | Purpose | Examples |
|------|--------|---------|---------|
| Keystone E2E | 1-2 | Full happy path across all layers | Ingest → process → alert → investigate |
| Feature | 12-18 | One per high-traffic feature | Dashboard, alerts, jobs, settings, login |
| Cross-cutting | 1-3 | Present on every page | Navigation, error handling, responsive layout |
| System-edge | 1-3 | Integration boundaries | API ingestion, syslog forwarding, websockets |

### Good Slices
- "User authentication" — login, logout, session expiry, password reset
- "Alert investigation" — alert detail page, evidence tabs, timeline, actions
- "Job scheduling" — create job, edit schedule, view runs, retry failed

### Bad Slices
- "The /api/ routes" — routes aren't user goals
- "Everything on the dashboard" — too broad for one agent
- "CSS and styling" — cross-cutting, not a coherent user goal

### Sizing
- 18-25 agents total for a typical multi-feature web app
- Each agent should finish in 20-60 minutes of browsing

## Fix-Lane Bucketing

Raw findings collapse into fix lanes at roughly 6-10× ratio:

| Strategy | When | Example |
|----------|------|---------|
| By file | Multiple findings touch same file | All `JobForm.tsx` → one lane |
| By feature | Related UX issues | All manual-trigger bugs → one lane |
| By layer | Same API contract bug | All "wrong response shape" → one lane |
| By symptom | Shared root cause | All "state lie" bugs → one lane |

### Lane Sequencing
1. **Blockers**: Login broken, API 500s on hot paths
2. **Contracts**: Data model changes, response shape fixes
3. **UI polish**: Copy, empty states, cosmetic issues

## Model Split

| Model | Best For |
|-------|----------|
| `gpt-5.4` | State-machine slices: auth flows, forms, wizards, scheduling |
| `claude-opus-4.7-high` | Semantic slices: data correctness, visualization, evidence rendering |

Split roughly 50/50 across slices within each cycle.

## Pitfalls

1. **Image not pushed after code fix** — always verify deployed digest
2. **Overlapping slice ownership** — same bug filed twice, triage nightmare
3. **Session name reuse** — state leaks across runs, false results
4. **Missing server logs** — workers can't reproduce 500s from screenshots alone
5. **Observations escalated to findings** — inflates counts, wastes repair turns
6. **Skipping live-verify** — unit tests can't see these bugs, that's the whole point
7. **Deploying before verifying image match** — abort if deployed image ≠ main HEAD
8. **Research code in prod image** — delete-from-prod finding, not a fix finding

## Driver Checklist

```
[ ] Pre-flight: URL, auth, deploy SHAs, logs, briefing
[ ] Slice user surface (18-25 agents, 4 tiers)
[ ] Initialize SQL tables + plan.md
[ ] Verify deployed image matches main HEAD
[ ] Loop:
    [ ] Dispatch dogfood agents in waves of 8-10 (mixed models)
    [ ] Aggregate JSON summaries into SQL
    [ ] Dedupe + bucket into fix lanes
    [ ] Sequence: blockers → contracts → UI polish
    [ ] For each lane: worktree, worker, fix, build, deploy, LIVE-VERIFY
    [ ] Merge lanes, validate, push, rebuild images, redeploy
    [ ] If empty: confirmation cycle (keystone + touched + wildcard)
    [ ] If confirmation clean: schedule final full-fan-out
[ ] Final full-fan-out on fresh deploy
[ ] Sign off; write final summary
```

## Entry Points

- **Command**: `/dogfood --url URL [--auth METHOD] [--deploy-cmd CMD] "description"`
- **Skill auto-activation**: "dogfood", "test the live app", "exercise the deployment"
- **Direct**: `Skill(skill="dogfood-readiness")`
