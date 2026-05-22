---
name: amplihack-guide
description: |
  How to install, invoke, and use the amplihack agentic coding framework for
  software development, code review, idea validation, release readiness, and
  live app dogfooding. Use this skill whenever someone asks about amplihack,
  wants to set up amplihack on a project, needs to run a development workflow,
  validate an idea, prepare a release, dogfood a deployed app, or wants to
  understand which amplihack command to use for their situation. Also use when
  someone mentions "agentic workflow", "multi-agent development", "release
  review loop", "idea validation", or asks how to automate code quality,
  release gates, or QA with AI agents.
---

# Amplihack Guide

Amplihack is an agentic coding framework that wraps GitHub Copilot CLI (and
Claude Code / Microsoft Amplifier) with structured workflows, specialized AI
agents, persistent memory, and quality gates. It turns a single-agent chat
into a multi-agent engineering system.

This skill teaches you how to install, invoke, and effectively use amplihack
across its major use cases.

## Installation

### Quick Start (one command)

```bash
# GitHub Copilot CLI
uvx --from git+https://github.com/kfriede/amplihack amplihack copilot

# Claude Code
uvx --from git+https://github.com/kfriede/amplihack amplihack claude

# Microsoft Amplifier
uvx --from git+https://github.com/kfriede/amplihack amplihack amplifier
```

This downloads amplihack, installs it, and launches an enhanced agent session
in your current directory. No separate install step needed — `uvx` handles
everything.

### Prerequisites

- **Platform**: macOS, Linux, or Windows via WSL
- **Runtime**: Python 3.11+, Node.js 18+
- **Tools**: git, [uv](https://docs.astral.sh/uv/) (Python package runner)
- **Recommended**: Rust/cargo (for the recipe runner — needed for orchestrated
  workflows like `/dev`)
- **Optional**: GitHub CLI (`gh`), Azure CLI (`az`)

### Install with Rust CLI (recommended for full features)

```bash
# Downloads the Rust binary + sets up framework assets
uvx --from git+https://github.com/kfriede/amplihack \
  amplihack-rust-trial install

# Then launch
uvx --from git+https://github.com/kfriede/amplihack amplihack copilot
```

### Per-Project Setup

Run amplihack from the root of your project repository. It reads the repo
structure and adapts its workflows to your codebase. No per-project config
file is needed — it auto-detects project type, test commands, and build tools.

---

## Core Concepts

### How It Works

When you launch amplihack, it enhances your agent session with:

1. **Workflows** — structured multi-step processes (22+ steps for development)
2. **Specialized agents** — architect, builder, reviewer, tester, security, etc.
3. **Skills** — auto-activating capabilities triggered by what you ask
4. **Commands** — explicit entry points like `/dev`, `/crucible`, `/dogfood`
5. **Quality gates** — philosophy compliance, test coverage, code standards

You interact normally — describe what you want in plain language. Amplihack
classifies your request and routes it through the appropriate workflow
automatically.

### Task Classification

Amplihack auto-classifies every request:

| Type | What Happens | Example |
|------|-------------|---------|
| **Q&A** | Direct answer, no workflow | "What is OAuth?" |
| **Operations** | Direct execution | "Run tests", "git status" |
| **Investigation** | Research workflow with specialized agents | "How does auth work in this codebase?" |
| **Development** | Full 22-step workflow with agents | "Add JWT authentication" |
| **Hybrid** | Investigation then development | "Understand the auth system, then add OAuth" |
| **Validation** | Crucible idea validation | "Should we build a CLI for this?" |

You don't need to classify manually — just describe your task and amplihack
routes it. But you can force a specific workflow with explicit commands.

---

## Use Cases and Commands

### 1. General Development — `/dev`

The primary command for any non-trivial task. Handles features, bugs,
refactoring, and investigations.

```
/dev Add a REST API endpoint for user profiles with pagination
```

**What happens:**
- Classifies the task (development, investigation, or hybrid)
- Decomposes into parallel workstreams if appropriate
- Executes via the recipe runner with specialized agents
- Reflects on goal achievement after each round
- Runs up to 3 rounds if the goal isn't fully achieved

**Real-world scenarios:**

```
# Feature development
/dev Implement webhook support for our notification system

# Bug fixing
/dev Fix the race condition in the job scheduler that causes duplicate runs

# Refactoring
/dev Refactor the auth middleware to support multiple providers without changing the API

# Investigation + implementation
/dev Understand how the caching layer works, then add Redis cache invalidation

# Multi-component work (auto-parallelized)
/dev Build a REST API for user management and a React form for user registration
```

**Monitoring:** The orchestrator prints status updates as it progresses through
rounds. If it's a long task, it may run 2-3 rounds. Each round's results are
reflected on before deciding whether to continue.

---

### 2. Idea Validation — `/crucible`

Subjects ideas to structured debate, research, and multi-agent critique
before you invest time building them.

```
/crucible "A CLI tool that generates API clients from OpenAPI specs"
```

**Modes:**

| Mode | Purpose | When to Use |
|------|---------|-------------|
| `refine` (default) | Socratic clarification | Fuzzy idea that needs sharpening |
| `scout` | Landscape reconnaissance | "What already exists?" |
| `spar` | Adversarial debate | "Should we build or buy?" |
| `research` | Deep curiosity exploration | "How do teams solve this?" |
| `internal` | Internal tool validation | "Should we build this for ourselves?" |
| `commercial` | Market validation | "Is this a viable product?" |
| `pivot` | Resurrect a killed idea | "Can we salvage this?" |

**Real-world scenarios:**

```
# Default (refine) — sharpen a fuzzy idea
/crucible "An app that tracks coffee shop WiFi quality"

# With reference docs
/crucible "Build a detection pipeline based on @/docs/ARCHITECTURE.md — is this worth building?"

# Specific mode — adversarial debate
/crucible --mode spar "Should we build our own auth or use Auth0?"

# Internal tool validation
/crucible --mode internal "CLI tool to convert our vault to a static site"

# Market validation
/crucible --mode commercial "Managed detection-as-code SaaS for mid-market SOCs"

# Landscape scan
/crucible --mode scout "Real-time collaboration for Jupyter notebooks"
```

**Monitoring:** Each mode runs as a recipe with defined steps. Refine has 5
steps (intake → clarification rounds → synthesis), spar has 5 steps (intake →
bull/bear debate → synthesis with verdict). Watch for the verdict: BUILD,
KILL, PIVOT, or SIMPLIFY.

---

### 3. Release Readiness — `/release-readiness`

Multi-agent code review loop for release validation. Dispatches parallel
specialist reviewers, repairs findings in isolated git worktrees, alternates
model providers between cycles, and stops when the codebase is clean.

```
/release-readiness "Prepare v2.0 for production deployment"
```

**What happens:**
1. Creates SQL state tables for tracking findings and cycles
2. Slices the codebase into specialist surfaces (by user-facing function)
3. Dispatches parallel reviewer agents — one per slice
4. Aggregates findings, deduplicates, triages
5. Creates git worktrees, dispatches repair workers
6. Merges fixes, runs full validation suite
7. Repeats with a different model provider (Anthropic ↔ OpenAI)
8. Terminates when 2 consecutive cycles produce zero findings from different providers
9. Verifies CI is green

**Real-world scenarios:**

```
# Basic release prep
/release-readiness "Validate v3.1 release candidate"

# Specific branch
/release-readiness --branch release/v2.0 "Review release branch"

# With pre-defined codebase slicing
/release-readiness --slices slices.yaml "Review with custom surface definitions"
```

**Monitoring:** The driver reports after each cycle:
- How many findings were discovered
- Which model was used
- How many were fixed vs false-positive
- Current consecutive-empties count

A typical run takes 2-6 cycles. Each cycle dispatches reviewers in waves of
8-10, so you'll see batches of agent completions. The SQL tables (`rr_findings`,
`rr_cycles`) are the source of truth for progress.

**When to use vs quality-audit:** Release-readiness validates the whole codebase
for deployment-blocking issues with model diversity. Quality-audit scans a
target path for code quality issues (dead code, test gaps, etc.). Use
release-readiness before cutting a release tag; use quality-audit during
routine development.

---

### 4. Live App Dogfooding — `/dogfood`

Browser-driven dogfood loop for deployed web applications. Parallel agents
exercise the live app as real users, capture evidence (screenshots, videos,
server logs), and repair workers fix + build + deploy + live-verify.

```
/dogfood --url https://staging.example.com "Validate v2.0 RC deployment"
```

**What happens:**
1. Pre-flight: verifies URL reachable, auth works, deploy SHAs match
2. Slices the app's user surface into 18-25 agent scopes (by user goal)
3. Dispatches browser-driving agents (via `agent-browser`) in waves
4. Aggregates findings, buckets into fix lanes
5. Repair workers: fix code → build image → deploy → live-verify with
   before/after screenshots
6. Merges fixes, rebuilds, redeploys
7. Confirmation cycle on touched slices with different models
8. Final full-fan-out on fresh deploy

**Real-world scenarios:**

```
# Staging deployment validation
/dogfood --url https://app.staging.example.com "Pre-release v2.0 dogfood"

# Local deployment
/dogfood --url http://localhost:3000 --deploy-cmd "docker compose up -d --build" "Test local stack"

# With specific auth
/dogfood --url https://app.example.com --auth api-key "Full app exercise"
```

**Monitoring:** The driver reports after each cycle:
- Findings per agent and severity breakdown
- Fix lanes created and their status
- Live-verify results (before/after screenshots)
- Confirmation cycle results

**Prerequisite:** The target app must be deployed and running. The driver
will ask you for: app URL, auth method, deploy command, and server log
command.

**When to use:** After running `/release-readiness` on the code. The code
review loop catches static bugs; the dogfood loop catches runtime/UX bugs
that only manifest in a real browser against a real deployment.

---

### 5. Other Useful Commands

```
# Code quality audit (iterative, not release-gating)
/analyze src/

# Quick fix with intelligent dispatch
/fix "pre-commit is failing on type checks"

# Adversarial debate on a specific decision
/debate "Should we use PostgreSQL or MongoDB for this service?"

# Consensus voting for critical decisions
/consensus "Which caching strategy: Redis, Memcached, or in-process?"

# N-version programming for critical code
/n-version "Implement the rate limiter — generate 3 independent versions"
```

---

## Workflow Composition: The Full Release Pipeline

For a comprehensive release, use the workflows in sequence:

```
Step 1: Validate the idea (if new product/feature)
  /crucible "Should we build X?"

Step 2: Develop the feature
  /dev "Implement X based on the validated spec"

Step 3: Code review loop (static analysis)
  /release-readiness "Prepare v2.0 release"

Step 4: Deploy to staging

Step 5: Dogfood loop (runtime validation)
  /dogfood --url https://staging.example.com "Validate v2.0 deployment"

Step 6: Ship
```

Each step catches a different class of bugs. Crucible catches bad ideas
before you build them. Development gets the code right. Release-readiness
catches code-level bugs across the whole codebase. Dogfood catches UX and
deployment bugs invisible to static review.

---

## Tips for Effective Use

### Let amplihack classify for you
Just describe what you want in plain language. Don't overthink which command
to use — if you say "investigate how auth works and then add OAuth support",
it auto-classifies as a hybrid task and handles both phases.

### Use `/dev` as your default
When in doubt, use `/dev`. It handles classification, decomposition, and
execution automatically. The other commands (`/crucible`, `/release-readiness`,
`/dogfood`) are for specific lifecycle phases.

### Provide context with file references
Use `@/path/to/file` to pull file content into your prompt:
```
/dev "Refactor the API based on the spec in @/docs/api-spec.yaml"
```

### Monitor long-running workflows
- **SQL tables** are the source of truth for release-readiness and dogfood
  (query with the `sql` tool)
- **plan.md** in the session folder has the human-readable cycle log
- **Agent completions** arrive as notifications — the driver resumes
  automatically

### Don't fight the architecture
Release-readiness and dogfood reviewers are explicitly instructed to evaluate
code AS IT IS — they won't recommend ripping out your auth system or
switching frameworks. Findings are surgical and fixable within your existing
architecture.
