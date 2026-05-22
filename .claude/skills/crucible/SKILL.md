---
name: crucible
version: 1.0.0
description: "Adversarial idea validation — subjects ideas to structured debate, market research, and multi-agent critique before building"
auto_activates:
  - "should I build"
  - "validate this idea"
  - "is this worth building"
  - "pressure test"
  - "adversarial review"
  - "kill or build"
  - "idea validation"
  - "should we build"
  - "build vs buy"
explicit_triggers:
  - /crucible
confirmation_required: false
token_budget: 4000
---

# Crucible Skill

## Purpose

Crucible is amplihack's adversarial idea-validation layer. It exists to answer the harder question before implementation starts:

**Should this be built, and if so, what exactly should be built?**

Crucible front-loads failure. It clarifies fuzzy ideas, researches the landscape, pressures claims under structured debate, and kills weak proposals early so amplihack does not waste effort building the wrong thing well.

## Mode Selection Guide

Pick the mode that matches the job:

- **Vague idea** -> `refine`
- **Want to understand the space** -> `scout`
- **Want to pressure-test** -> `spar`
- **Want to sell it** -> `commercial`
- **Building for yourself/org** -> `internal`
- **Curious exploration** -> `research`
- **Killed idea** -> `pivot`

## Invocation Examples

```bash
/crucible "An app that tracks coffee shop WiFi quality"
/crucible --mode internal "CLI tool to convert our vault to static site"
/crucible --mode spar "Should we build auth or use Auth0?"
```

## Routing and Execution

When this skill is invoked, it should:

1. Detect the best mode from the user's input, or ask the user to choose when the intent is still ambiguous.
2. Map that mode to the matching recipe:
   - `refine` -> `amplifier-bundle/recipes/crucible-refine.yaml`
   - `scout` -> `amplifier-bundle/recipes/crucible-scout.yaml`
   - `spar` -> `amplifier-bundle/recipes/crucible-spar.yaml`
   - `commercial` -> `amplifier-bundle/recipes/crucible-commercial.yaml`
   - `internal` -> `amplifier-bundle/recipes/crucible-internal.yaml`
   - `research` -> `amplifier-bundle/recipes/crucible-research.yaml`
   - `pivot` -> `amplifier-bundle/recipes/crucible-pivot.yaml`
3. Construct the recipe-runner command for the selected mode, for example:

```bash
amplihack recipe run amplifier-bundle/recipes/crucible-<mode>.yaml \
  -c idea_description="<idea description>" \
  -c repo_path="."
```

For pivot mode, pass the prior `KillReport` into `crucible-pivot.yaml` instead of treating it like a fresh idea.

## Output Types

Crucible produces different outputs depending on the mode:

- `refine` -> `IdeaCapture` / enriched framing
- `scout` -> `ScoutReport`
- `spar` -> `SparReport`
- `commercial` -> `ProductBrief` or `KillReport`
- `internal` -> `ProductBrief` or `KillReport`
- `research` -> `ResearchBrief`
- `pivot` -> `PivotBrief` or `FinalKill`

These outputs are intentionally decision-oriented. Crucible is not implementation planning; it is adversarial validation.

## Handoff to Build Execution

A surviving idea hands off through `amplifier-bundle/tools/crucible-handoff.sh`.

Primary path:

`ProductBrief` -> `crucible-handoff.sh` -> `smart-orchestrator`

The handoff maps brief fields into build context so only validated ideas flow into amplihack's implementation workflow.
