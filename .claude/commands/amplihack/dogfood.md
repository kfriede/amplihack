---
name: dogfood
version: 1.0.0
description: Multi-agent dogfood → fix loop for deployed web applications
triggers:
  - "dogfood"
  - "dogfood the app"
  - "test the live app"
  - "exercise the deployment"
invokes:
  - type: skill
    name: dogfood-readiness
dependencies:
  required:
    - skills/dogfood-readiness/SKILL.md
    - amplifier-bundle/agents/specialized/dogfood-tester.md
    - amplifier-bundle/agents/specialized/dogfood-repair-worker.md
    - amplifier-bundle/context/DOGFOOD_READINESS.md
examples:
  - '/dogfood --url https://app.staging.example.com "Validate v2.0 RC deployment"'
  - '/dogfood --url http://localhost:3000 --deploy-cmd "docker compose up -d --build" "Test local deployment"'
---

# /dogfood

Multi-agent browser-driven dogfood loop that takes a deployed web app from
"the tests pass" to "exercised end-to-end by simulated users and every
finding fixed."

## Usage

```
/dogfood --url URL [--auth METHOD] [--deploy-cmd CMD] [--log-cmd CMD] "description"
```

### Options

- `--url URL` — Browser-reachable URL of the deployed application (required)
- `--auth METHOD` — Authentication method: `password`, `api-key`, `oidc`,
  or `state:<path>` for agent-browser state file
- `--deploy-cmd CMD` — How to redeploy after a fix (e.g., `docker compose up -d --build`
  or `helm upgrade ...`)
- `--log-cmd CMD` — How to get server logs (e.g., `kubectl logs -n app deploy/backend`)
- `"description"` — What you're validating (e.g., "v2.0 RC on staging")

### Pre-Flight

The workflow verifies these before launching any dogfood agent:
1. Application URL is reachable
2. Authentication works
3. Deployed image SHAs are known
4. Server logs are accessible
5. Deploy path is confirmed

### What It Does

1. Pre-flight verification of the live deployment
2. Slices the app's user surface into 18-25 agent scopes (by user goal)
3. Runs the dogfood → fix loop:
   - Dispatches parallel browser-driving agents (one per slice, mixed models)
   - Aggregates findings, dedupes, buckets into fix lanes
   - Creates worktrees, dispatches repair workers
   - Workers: fix → build image → deploy → LIVE-VERIFY with before/after screenshots
   - Driver merges, validates, pushes, rebuilds, redeploys
4. Confirmation cycle on touched slices with different models
5. Final full-fan-out on fresh deploy
6. Produces a final summary with all evidence

### Termination

The loop stops when:
- A full cycle produces zero critical/high findings, AND
- A confirmation cycle (different models, scoped to touched slices) is also clean

### Relationship to Release-Readiness

These are complementary workflows:
1. Run **release-readiness** on the code → fix code-level issues
2. Deploy the release candidate
3. Run **dogfood** on the live app → fix runtime/UX issues invisible to code review

### See Also

- `skills/dogfood-readiness/SKILL.md` — full driver protocol
- `amplifier-bundle/agents/specialized/dogfood-tester.md` — browser-driving agent
- `amplifier-bundle/agents/specialized/dogfood-repair-worker.md` — repair worker with live-verify
- `amplifier-bundle/context/DOGFOOD_READINESS.md` — reference documentation
- `skills/release-readiness/SKILL.md` — the code-review sibling workflow
