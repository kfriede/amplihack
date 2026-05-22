# Crucible — Adversarial Idea Validation

Crucible is amplihack's idea-validation layer. It answers a harder question than implementation planning:

**Should this be built, and if so, what exactly should be built?**

It front-loads failure by subjecting ideas to adversarial scrutiny **before** code is written. The goal is not to protect ideas. The goal is to kill weak ones early, sharpen salvageable ones, and hand stronger ideas into build workflows.

Crucible is **not** a separate product. It is a set of recipes, agents, and handoff paths inside amplihack.

## Core Idea

Crucible exists to reduce waste from building the wrong thing well.

It is useful when:

- the idea is vague and needs framing
- the landscape is unclear
- the thesis sounds plausible but unproven
- the cost of being wrong is meaningful
- you need a go / no-go judgment before implementation

## Seven Modes

| Mode | Intent | Kill Authority | Output | When to Use |
|------|--------|---------------|--------|-------------|
| Refine | Socratic clarification | None | Enriched IdeaCapture | "I have a half-baked thought" |
| Scout | Landscape recon | None | ScoutReport | "What's out there?" |
| Spar | Adversarial sharpening | None (human decides) | SparReport + forcing function | "Pressure-test this" |
| Commercial | Market validation | Aggressive (single flaw) | ProductBrief or KillReport | "Should I sell this?" |
| Internal | Internal tool validation | Reluctant (convergent) | ProductBrief or KillReport | "Should I build this for us?" |
| Research | Possibility exploration | Barely (physics only) | ResearchBrief | "What could exist?" |
| Pivot | Idea resurrection | Final kill | PivotBrief or FinalKill | "Can we salvage this?" |

## Core Agents

### `crucible-intake`
Turns natural language into a structured idea record. It extracts the problem, audience, hypothesis, alternatives, constraints, goal type, and suggested next mode.

### `crucible-researcher`
Does dual-mode research:

- **Recon mode** for landscape mapping without advocacy
- **Validation mode** for evidence that feeds debate and go / no-go decisions

### `crucible-debate`
Runs adversarial debate between Bull, Bear, and Synthesizer roles. It applies burden-of-proof rules and mode-specific kill authority to decide whether the idea survives.

### `crucible-rubber-duck`
A cross-cutting critic that reviews phase outputs for weak evidence, hidden assumptions, bias, and repeated mistakes. It is universal infrastructure, not a Crucible-only mode.

## Pipeline Composition

Modes can run standalone or be chained manually.

Common flow:

`refine -> scout -> spar -> commercial|internal`

Practical rules:

- `Refine` clarifies fuzzy inputs before stronger judgment is attempted
- `Scout` maps the landscape without pretending to decide
- `Spar` sharpens the thesis under pressure without killing it automatically
- `Commercial` or `Internal` performs actual validation with kill authority
- `ScoutReport` and `SparReport` should pre-seed validation modes
- every transition is an explicit human decision

Example chain:

`crucible-refine` -> `crucible-scout` -> `crucible-commercial`

Crucible does not assume that exploration should automatically become commitment.

## Key Mechanics

### Burden of Proof

- **Commercial:** Bull carries the burden of proof. The idea must earn survival.
- **Internal:** Bear carries the burden of proof. Skepticism must prove the idea fails.

### Kill Thresholds

- **Commercial:** a single fatal flaw can kill the idea
- **Internal:** kill requires convergent failure across the case, not one cheap objection
- **Research:** only reality-level constraints should kill; taste and market objections are secondary

### Rubber Duck Fires

Rubber duck review runs after every substantive phase. In validation modes, that typically means three reviews:

1. after intake framing
2. after research
3. after debate or brief synthesis

### Model Diversity

Crucible achieves diversity primarily through persona and prompt differentiation. Bull, Bear, Synthesizer, researcher, and rubber duck are intentionally framed to think differently.

This can later be upgraded to true multi-model execution without changing the conceptual design.

### Isolation

Debate roles argue independently until synthesis. Bull and Bear should not collapse into premature consensus. Adversarial tension is a feature, not a bug.

## Quality Expectations

Crucible output is only useful if it stays sharp.

- **No strawmen** — Bear must attack the strongest version of Bull's case
- **No fake agreement** — if roles converge too easily, the prompts or evidence are weak
- **No balanced mush** — synthesis must take a position
- **No sycophantic survival** — ideas need evidence to live
- **No orphaned kills** — every `KILL` should generate pivot candidates for `Pivot` mode

## Amplihack Handoff

A surviving idea hands off through `crucible-handoff.sh` into build orchestration.

Primary mapping:

- `one_liner` -> `task_description`
- `architecture` -> `context`
- `stories` -> `workstreams`

Typical path:

`ProductBrief` -> smart-orchestrator

Crucible stops before implementation. Building requires explicit user confirmation.

## Invocation

```bash
# Via skill
/crucible "An app that tracks coffee shop WiFi quality"
/crucible --mode internal "CLI tool to convert our vault to a static site"
/crucible --mode spar "Should we build auth or use Auth0?"

# Via recipe runner directly
amplihack recipe run crucible-internal.yaml -c idea_description="..."
```

## Operating Summary

Use Crucible when the biggest risk is not bad code, but building the wrong thing. It is the adversarial front-end to amplihack's build system: clarify, research, attack, validate, then hand off only what survives.
