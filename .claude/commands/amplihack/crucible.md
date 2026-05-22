---
name: crucible
version: 1.0.0
description: Adversarial idea validation
triggers:
  - "should I build"
  - "validate this idea"
  - "is this worth building"
  - "pressure test"
  - "build vs buy"
invokes:
  - type: recipe
    name: crucible-<mode>
dependencies:
  required:
    - amplifier-bundle/context/CRUCIBLE.md
    - amplifier-bundle/recipes/crucible-refine.yaml
    - amplifier-bundle/recipes/crucible-scout.yaml
    - amplifier-bundle/recipes/crucible-spar.yaml
    - amplifier-bundle/recipes/crucible-commercial.yaml
    - amplifier-bundle/recipes/crucible-internal.yaml
    - amplifier-bundle/recipes/crucible-research.yaml
    - amplifier-bundle/recipes/crucible-pivot.yaml
    - amplifier-bundle/tools/crucible-handoff.sh
examples:
  - "/crucible \"An app that tracks coffee shop WiFi quality\""
  - "/crucible --mode internal \"CLI tool to convert our vault to static site\""
  - "/crucible --mode spar \"Should we build auth or use Auth0?\""
---

# Crucible Command

## Usage

`/crucible [--mode MODE] "idea description"`

## Purpose

Run amplihack's adversarial idea-validation flow before implementation. Crucible clarifies ideas, researches the landscape, pressure-tests assumptions, and decides whether the idea should survive long enough to enter build orchestration.

## Modes

- `refine`
- `scout`
- `spar`
- `commercial`
- `internal`
- `research`
- `pivot`

## Options

- `--mode MODE` - explicitly select mode (auto-detected if omitted)
- `--pivot KILL_REPORT` - enter pivot mode with a `KillReport`
- `--dry-run` - show what would be executed without running

## Default Mode Detection Logic

If `--mode` is omitted, detect mode in this order:

1. If `--pivot` is present, use `pivot`.
2. If the request explicitly says **pressure test**, **adversarial review**, **kill or build**, or similar, use `spar`.
3. If the idea contains commercial keywords such as **sell**, **customers**, **revenue**, **pricing**, **market**, **startup**, or **SaaS**, use `commercial`.
4. If the idea contains internal keywords such as **internal**, **team**, **org**, **company**, **our**, **workflow**, **tooling**, or **build vs buy**, use `internal`.
5. If the idea is still vague, underspecified, or half-formed, suggest `refine`.
6. Otherwise default to `scout` for landscape understanding.

## EXECUTION INSTRUCTIONS FOR CLAUDE

When this command is invoked, you MUST:

1. Parse `--mode`, `--pivot`, and `--dry-run`.
2. Determine the mode using the detection logic above when `--mode` is absent.
3. Select the corresponding recipe:
   - `refine` -> `amplifier-bundle/recipes/crucible-refine.yaml`
   - `scout` -> `amplifier-bundle/recipes/crucible-scout.yaml`
   - `spar` -> `amplifier-bundle/recipes/crucible-spar.yaml`
   - `commercial` -> `amplifier-bundle/recipes/crucible-commercial.yaml`
   - `internal` -> `amplifier-bundle/recipes/crucible-internal.yaml`
   - `research` -> `amplifier-bundle/recipes/crucible-research.yaml`
   - `pivot` -> `amplifier-bundle/recipes/crucible-pivot.yaml`
4. Construct the recipe runner invocation.

### Standard Invocation

```bash
amplihack recipe run amplifier-bundle/recipes/crucible-<mode>.yaml \
  -c idea_description="<idea description>" \
  -c repo_path="."
```

### Pivot Invocation

```bash
amplihack recipe run amplifier-bundle/recipes/crucible-pivot.yaml \
  -c kill_report="<KillReport JSON or path>" \
  -c repo_path="."
```

### Dry Run Behavior

If `--dry-run` is present, print the resolved mode, recipe path, and final command, then stop without executing.

## Outputs

- `refine` -> enriched `IdeaCapture`
- `scout` -> `ScoutReport`
- `spar` -> `SparReport`
- `commercial` -> `ProductBrief` or `KillReport`
- `internal` -> `ProductBrief` or `KillReport`
- `research` -> `ResearchBrief`
- `pivot` -> `PivotBrief` or `FinalKill`

If Crucible returns a `ProductBrief`, the next step is handoff into build orchestration through `amplifier-bundle/tools/crucible-handoff.sh`.
