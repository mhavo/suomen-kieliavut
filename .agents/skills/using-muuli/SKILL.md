---
name: using-muuli
description: Use when receiving a coding task whose description is incomplete or high-level — an audit, bug hunt, bug fix, or feature delivery — before starting research, spec work, or implementation. Also use when unsure how much process (spec loops, subagent waves, review) a task deserves. Muuli complements Superpowers — it does not depend on it. When a counterpart Superpowers skill is present, load and cooperate with it.
---

# Using Muuli

## Contents

Nothing here is read in order. Read `## Overview`, then jump to the sections
your task names; skip the rest.

| Your task | Sections to read |
|---|---|
| Route a task, pick the process budget | Phase selection matrix · V0 — Clarify the goal · Direct fix protocol · V1 — Research · V2–V6 — Route to the workflow skills |
| Deliver SEVERAL milestones across sessions (a program, not one delivery) | Phase selection matrix (task-type entry points) · Artifact location — then muuli:orchestrating-milestones |
| Start or supervise a ralph loop run on an existing tracker | Phase selection matrix (task-type entry points) — then muuli:launching-ralph-runs |
| Dispatch a subagent or reviewer | Subagent briefs · Scaling rules · Reviewer fallback |
| Write any artifact | Artifact location (Naming · Artifact paths · Committed by default and `.gitignore`) · Language rule · Density rule · Scaling rules |
| Applies everywhere | Relationship to Superpowers · Red flags |

## Overview

This hub routes a task to the muuli workflow skills; each phase below names
the skill that runs it. The master pattern for large work:

```
V0 Goal → V1 Research → V2 Spec → V3 Spec loop (redteam ⟷ Realism Hat) →
V4 Tracker + plans → V5 Wave-supervised coding → V6 Audit loop (at the end)
```

Three cross-cutting principles apply at every phase:

1. **External verification.** Never act as the sole judge of your own work. Use
   an isolated reviewer (codex CLI, or a clean-context subagent — see Reviewer
   fallback). Filter ALL external feedback before acting: *"findings may be
   YAGNI or hallucination — or fully valid. Verify each."*
2. **Dialectic both ways.** Redteam (*"this won't work and isn't safe"*) versus
   ponytail (*"you built a doomsday-proof OS when the goal was to move a
   file"*). Truth is at the intersection. Redteam WITHOUT a Realism Hat /
   ponytail gate is forbidden — it is a proven source of YAGNI bloat. Ponytail
   WITHOUT the never-lazy list is equally forbidden.
3. **Clean context as evidence.** Assessments and lean distillations are done
   by a subagent or fresh session with NO conversation-history baggage.

## Relationship to Superpowers

Muuli complements Superpowers — it does not depend on it. When a counterpart
Superpowers skill is present, load and cooperate with it: e.g.
`superpowers:brainstorming` at V2, `test-driven-development` and
`using-git-worktrees` in coding, `systematic-debugging` in bug work,
`writing-plans`/`executing-plans` around V4–V5, `verification-before-completion`
and `requesting-code-review` at gates. When it is absent, the muuli skill for
that phase covers the same ground standalone. Never hard-require a
`superpowers:` skill; treat the names above as examples, not a checklist. This
is the authoritative statement — each workflow skill only points back here.

## Phase selection matrix

Infer the task type if not stated. First choose the **process budget** — the
lightest path that can safely satisfy the request:

| Budget | Use when | Muuli path |
|---|---|---|
| **direct** | One known failing test, one-file/surgical bug, README wording, config typo, or another well-scoped edit with clear success criteria | No spec/tracker/supervisor. Reproduce or inspect the cause, make the smallest TDD/surgical change, then run the available local gate yourself. |
| **light** | Targeted review/audit of a diff, branch, PR, or named feature area; small fix that needs a written mini-plan because it touches several files | Use only the phase skill that matches the risk (`muuli:auditing-code` for targeted existing-code review; direct TDD + optional mini-plan for the fix). |
| **standard** | Ordinary feature delivery with uncertain requirements or multiple implementation steps | V0→V3 spec loop at capped depth, then V4/V5 only if the work truly needs waves/subagents. |
| **full** | Broad whole-codebase audit, unclear bughunt, safety/data-loss/security invariants, or multi-wave feature delivery | Full matching workflow: lens/finder fanout, full spec loop when warranted, wave supervision, and final audit gate. |
| **program** | SEVERAL milestones delivered end-to-end across many sessions, without prompting per feature | Not a bigger delivery — one altitude up: muuli:orchestrating-milestones. Each milestone it promotes then picks its own budget from this table. |

If a request is documentation-only, do not route to `muuli:ai-docs` unless the
user asks for the AI-assistant documentation package (`AGENTS.md`, `docs/ai-*`,
manifest, drift/update), not just README, JSDoc/docstring, OpenAPI, Docusaurus,
design-doc, or standalone `CLAUDE.md` prose.

Then use the phase matrix:

| Phase | Skill | audit | bughunt | fixbug | deliver-feature |
|---|---|---|---|---|---|
| V0 goal | (this skill) | light (SCOPE+FOCUS) | light | direct/light | full (explicit completion condition) |
| V1 research | (this skill) | full: lens fanout · light: targeted | full (finder fanout) | targeted diagnosis | full |
| V2 spec | muuli:writing-specs | – | – | – (issue text suffices) | living draft → frozen spec |
| V3 spec loop | muuli:writing-specs | – | – | root-cause confirmation | by risk: 1–2 rounds clean subagent; safety-critical → full loop to convergence |
| V4 tracker+plans | muuli:planning-waves | – | `.muuli-workflows/BUGFIX.md` | – / light series folder `<date>-<series>/` (tracker + mini-plan) | series folder `<date>-<series>/` (tracker + wave plans) |
| V5 subagent coding | muuli:supervising-waves | – | – | direct TDD fix | wave supervisor |
| V6 audit loop | muuli:auditing-code | full audit → muuli:running-full-audits | muuli:hunting-bugs gate | gate run yourself | audit loop, or light code review → remediation plan |

Task-type entry points: **bughunt** → muuli:hunting-bugs. **Full audit** →
muuli:running-full-audits. **Improving a skill package (the target is SKILL.md
files, not program code)** → muuli:improving-skills. **Mining
practiced-but-undocumented working habits for recurring patterns (the corpus is
evidence of past work — session transcripts, git history, memory/notes — rather
than the program code itself)** → muuli:researching-workflows. **Delivering
SEVERAL milestones across many sessions without per-feature prompting (a
program above the phase matrix — each milestone runs its own V0–V6 lifecycle)**
→ muuli:orchestrating-milestones; one delivery, however many waves, stays in the
phase matrix above. **Handing a finished tracker to the ralph loop driver and
leaving it running unattended — or supervising, answering or handing back a run
already going** → muuli:launching-ralph-runs (the session outside the loop; the
skills above are what the loop's own iterations load). Context running low at
any phase → muuli:handing-off.

## V0 — Clarify the goal (Golden Rule)

Test: **would a colleague with minimal context understand the task?** If not,
ask at most 3 targeted questions; otherwise proceed without ceremony. For
feature deliveries, write an explicit completion condition the work must
satisfy before stopping — record it at the top of the living draft
(`<date>-<series>/FEATURE.md`) at V0, then move it to the top of the tracker's
locked-decisions section when V4 creates it; it becomes the supervisor's goal
text in V5.

## Direct fix protocol

Use this for **direct** budget work. Do not create `.muuli-workflows/`
artifacts unless the direct attempt exposes broader uncertainty.

1. Reproduce or inspect the known failure/cause.
2. Add or use the smallest failing test/trace when behavior is code-visible.
3. Patch the narrow cause; avoid unrelated refactors.
4. Run the available local gate yourself (targeted test first, broader gate if
   the touched area warrants it).
5. Report the changed files and verification.

## V1 — Research

Code graph / index tooling first if available; `rg`/`ast-grep` for literals.
Parallel subagents for independent scans — but verify their quality. Use a
clean-context subagent when you need an uncontaminated assessment.

## V2–V6 — Route to the workflow skills

- **V2+V3 spec + spec loop** → muuli:writing-specs
- **V4 tracker + plans** → muuli:planning-waves (tracker is ralph-compatible:
  checkbox state, executor-skill header)
- **V5 wave-supervised coding** → muuli:supervising-waves
- **V6 audit loop** → muuli:auditing-code (light) or muuli:running-full-audits
  (task type "audit", broad scope)

**"Gate run yourself"** (matrix) = the project's full uncached verification — the
stack's available equivalents of build + vet/lint + full test suite with caching
disabled — run personally, never delegated. That is the direct/fixbug gate,
which has no waves; a WAVE gate's scope is muuli:planning-waves'. Skip stages the project genuinely
lacks (no build step, no configured linter) rather than inventing them.

## Subagent briefs

Every brief uses the XML skeleton — self-contained, with WHY on constraints:

```xml
<objective>what + why it matters + end goal</objective>
<context>stack, files to read (spec/plan paths), locked contracts, exact API signatures</context>
<requirements>explicit, numbered; forced skills repeated here — for ANY coding
task: TDD + the language- and task-specific skills the coder discovers and loads
(typescript-pro, golang-pro, python-pro, frontend-design, …)</requirements>
<output>exact file paths</output>
<verification>commands the agent must run; what must pass</verification>
<success_criteria>measurable; verification always</success_criteria>
```

**Forced skills rule:** every agent doing a programming task MUST first
**discover and load the available language- AND task-specific specialist
skills** for its language/stack and its task, plus TDD — not merely a fixed
language list. The brief names the ones the author knows with their exact installed
names (TDD is typically superpowers:test-driven-development; language skills
are unprefixed); the coder additionally checks what is installed for its
language/task and loads those too. Repeat even when the spec already names them.

Parallelization decision: shared files or data flow between tasks → run
sequentially; independent modules → run in parallel.

## Scaling rules

- Loop depth tracks risk: work touching data-loss or safety invariants gets
  the full spec loop (external reviewer + Realism Hat), and a pre-mortem if
  directional; everything else gets one clean-context challenger. The same
  trigger scales V6: safety-critical work gets the full audit loop (redteam →
  gate, plus inversion), not the light code review.
- **Model tier tracks difficulty, not a fixed default.** Mechanical/boilerplate
  work (scaffolding, config, rote refactor) runs fine on a cheaper model
  (Sonnet/Haiku); judgment-heavy work (core algorithm, concurrency,
  security-sensitive paths) gets a stronger one — the same tiering muuli already
  applies to audit lenses and research sweeps. This governs coding waves too
  (planned in V4, honored at V5 dispatch). Never downgrade the supervisor's own
  gate verification — judgment stays on the strong model.
- HARDENING_NOTES lives for the whole lifecycle in two tiers (both paths in the
  artifact table). Resolve the read path by scope: delivery work reads its own
  file + the cross-cutting file; a whole-repo audit reads the union
  `glob(<BASE>/*/HARDENING_NOTES.md)` + the cross-cutting file; context-less
  package work (muuli:improving-skills) reads the cross-cutting file.
- **Verification at wave gates, at the END of waves — never between individual
  tasks.** Per-task review is excess ceremony (the documented superpowers
  failure mode muuli exists to avoid). Gate SCOPE tracks the wave the same way
  loop depth tracks risk: a mid-delivery gate runs the wave's own surface, the
  full uncached suite is the delivery's LAST gate and any wave touching shared
  surface (muuli:planning-waves).
- Context running low or phase changing → muuli:handing-off, then stop. Never
  continue on a tired context.

## Artifact location — the workflow base directory `<BASE>`

EVERY workflow artifact goes under a single **workflow base directory** `<BASE>`
in the target repo; never scattered loose at the repo root. **`<BASE>` is
configurable — resolve it ONCE per session, then treat it as the single source
of truth:**

- Default: `.muuli-workflows/`.
- Alternative: `docs/muuli/` — co-locates with `docs/` plans
  (Superpowers-adjacent, one reviewable committed tree).
- Resolution: use whichever `<BASE>/` already exists in the repo; if neither
  (or both) exists, use the default `.muuli-workflows/`. A split base — V3
  writing one base while V6 reads another — silently empties loop memory, so
  never let it drift mid-delivery.
- Inject the resolved ABSOLUTE path into every subagent brief. A history-less
  reviewer must be handed the path, never left to guess it.
- Everywhere these skills write a literal `.muuli-workflows/…` path below, read
  it as `<BASE>/…` under your configured base.

### Naming — a delivery series is a dated folder

Every wave-supervised delivery (a feature, or a fixbug) lives in ONE
self-contained, portable folder `.muuli-workflows/<date>-<series>/` (`<date>` =
`date +%F` → `2026-06-23`; `<series>` = short slug), so collisions cannot happen.
The folder holds that delivery's tracker, spec, sub-specs, and wave plans
together — copy or move
the whole series in one `cp -r`, and re-using a name on a later day never
overwrites an earlier delivery (the date prefix disambiguates; if two deliveries
would share both the same day AND slug, add a distinguishing suffix to the folder
— the prefix is date-granular). Cross-cutting artifacts that are NOT tied to one
delivery stay at the `<BASE>` top level — see the artifact table.

### Artifact paths

| Artifact | Path |
|---|---|
| **Delivery series (one portable folder)** | `.muuli-workflows/<date>-<series>/` |
| ↳ Master tracker | `<date>-<series>/IMPLEMENTATION_TRACKER.md` |
| ↳ Living draft → frozen spec | `<date>-<series>/FEATURE.md` → `<date>-<series>/SPEC.md` (multi-wave: `<date>-<series>/specs/W*-*.md` sub-specs) |
| ↳ Wave plans | `<date>-<series>/plans/W*-*.md` |
| ↳ ADRs (rationale moved out of the spec) | `<date>-<series>/adr/NNN-<slug>.md` — one decision per file: context, decision, consequences. The sink for every "why" too long for one spec line. A brief's `<context>` names the ADR dir whenever a wave turns on a decision recorded there, so relocated rationale stays reachable. |
| ↳ Delivery loop memory (committed in-folder) | `<date>-<series>/HARDENING_NOTES.md` |
| ↳ Ralph handoff (ephemeral) | `<date>-<series>/IMPLEMENTATION_TRACKER.handoff.md` |
| Milestone program folder (muuli:orchestrating-milestones — a program of several deliveries, not a delivery) | `.muuli-workflows/<date>-milestones/` |
| ↳ Program tracker + unpromoted ideas | `<date>-milestones/IMPLEMENTATION_TRACKER.md` · `<date>-milestones/BACKLOG.md` |
| Standalone committed plan (audit remediation) | `.muuli-workflows/plans/REMEDIATION-<date>-<scope>.md` |
| Audit roadmap (product-gap/feature candidates from a full audit) | `.muuli-workflows/plans/ROADMAP-<date>-<topic>.md` |
| Full-audit lens + gate + synthesis reports (`<timestamp>` = `date +%F_%H%M%S` → `2026-06-23_143012`) | `.muuli-workflows/audit-<timestamp>/{redteam,ponytail,inversion,<lens>,gate,comprehensive}.md` |
| Spec-loop redteam (deleted each round) | `.muuli-workflows/<date>-<series>/spec-loop/redteam.md` |
| Bughunt findings log (singleton, fixed name — read by this canonical path) | `.muuli-workflows/BUGFIX.md` |
| Workflow-research report (session/git/notes mining) | `.muuli-workflows/research/RESEARCH-<date>-<topic>.md` |
| General handoff, non-ralph (archive prev before overwrite) | `.muuli-workflows/HANDOFF.md` |
| Ralph SUPERVISOR handoff (the session outside the loop; overwritten, never archived) | `.muuli-workflows/<project>-supervision-<date>.handoff.md` |
| Cross-cutting loop memory (package/codebase/threat-model-wide; committed) | `.muuli-workflows/HARDENING_NOTES.md` |
| Series table-of-contents (committed; one pointer line per series or milestone program, plus one to the cross-cutting memory — pointers only, never suppression content — a navigation aid, not a second singleton) | `.muuli-workflows/INDEX.md` |
| Skill-package regression assets (the ONE exception, owned by muuli:improving-skills) | target repo `test/{scenarios,fixtures,results}/` |

The flat `.muuli-workflows/plans/` directory holds **only standalone committed
plans** (audit REMEDIATION and ROADMAP) — never trackers, never wave plans.
Those belong to a delivery series and live inside its `<date>-<series>/` folder.
If an audit remediation grows large enough to need waves and a tracker to
execute, it stops being a standalone plan and becomes a normal delivery series:
open `<date>-<series>/`, and the tracker + wave plans go there
(muuli:planning-waves convention), not the flat `plans/` root — a stray
tracker or `W*-*.md` there is drift.

### Committed by default and `.gitignore`

On first use, create `<BASE>` and ensure the target repo's `.gitignore` ignores
ONLY the genuine ephemerals — everything else under `<BASE>` is **committed by
default**:

```
# muuli workflow artifacts: committed by default. Only genuine ephemerals are
# ignored — each with a stated reason. <BASE> = .muuli-workflows or docs/muuli.
<BASE>/**/spec-loop/          # redteam.md is deleted each round; never a deliverable (nested under the delivery series)
<BASE>/audit-*/              # per-run raw working dir; the committed deliverable is the REMEDIATION plan
<BASE>/**/*.handoff.md       # ralph transient coordination state, regenerated each handoff
```

Commit-by-default is deliberate: it makes each delivery-series folder
self-contained on a fresh clone (the `cp -r` portability promise) and keeps loop
memory alive across teammates. This ignore list is identical under both base
choices. Use `docs/` only when it is the configured base; never promote
artifacts there otherwise.

## Language rule

**Every artifact is ALWAYS written in English — no exceptions** — tracker,
specs, plans, briefs, reports, handoffs, HARDENING_NOTES, BUGFIX, ai-docs —
regardless of the conversation language. Even in a fully Finnish (or any
non-English) conversation, every artifact's headings, body, and notes are
English. English costs fewer tokens and is unambiguous next to code; only chat
output follows the user's language.

## Density rule

**Artifacts are dense, not long — always on, no levels.** Same house style as
muuli:ai-docs. Applies to every artifact: spec, living draft, plan, tracker,
brief, report, handoff, notes.

- **Cut filler, hedging, and narration.** No "just / really / basically /
  simply / it is worth noting that", no "This document describes…", no
  restating the task before doing it, no tool-call narration.
- **State each fact once.** No artifact or section repeats what another
  already says — cite it. (Deliberate exceptions, always inlined, never cited:
  the forced-skills line, and the locked contracts + exact API signatures a
  dispatch brief carries — a history-less coding agent must receive those in
  the brief. Citing them instead is what burned 73 tool calls.)
- **Tables and one-claim-per-line lists over paragraphs.** Fragments are fine
  inside a table cell or a template field.
- **Facts and decisions only** — no tutorials, no restating language/framework
  defaults, no debate history (that is an ADR).
- **Keep full words and normal grammar.** Never drop articles, never invent
  abbreviations (`cfg`/`impl`/`req`), never use `→` as a verb in prose: they
  save no tokens under the tokenizer and cost the reader clarity. (`→` is fine
  inside a table cell or a `key → value` mapping.)

**Shorter never means vaguer.** If it will not fit: split the task, cite
another artifact, or move rationale to an ADR — never "TBD" or "handle edge
cases".

**Never compressed** — these keep full sentences and their WHY: R-numbered
locked decisions and invariants, interface contracts and signatures, the V0
completion condition (verbatim), the REJECTED list in any report, and `Gate:`
criteria. Ralph's `- [ ]` task lines and `Gate:` prose lines keep their exact
form — never convert wave tasks into a table.

## Reviewer fallback

`[REVIEWER]` in the workflow-skill prompts means: `codex exec --sandbox
workspace-write "<prompt>"` if the codex CLI is available (`command -v codex`);
otherwise dispatch a fresh general-purpose subagent with the same prompt text.
The property that matters is isolation — no conversation history.

## Red flags

| Thought | Reality |
|---|---|
| "Redteam found it, so fix it" | Every finding passes the Realism Hat first. Direct-apply is the documented bloat path. |
| "The agent reported all green" | Agents have reported green from stale caches. Run the gate yourself, uncached. |
| "I'll review after each task" | Review at wave gates, at the END of the wave. Per-task review is ceremony. |
| "The coding agent can start right away" | Not before its brief forces the language- AND task-specific skills it must discover and load (typescript-pro, frontend-design, …) + TDD. |
| "This concern came up again" | Check HARDENING_NOTES first — deferred/rejected items don't get re-litigated. |
| "Spec needs one more mechanism" | SPEC BLOAT CHECK: is the design heavier than the product risk justifies? |
| "Context is long but I can push on" | muuli:handing-off, then stop. |
| "Six milestones to ship overnight — one tracker, six waves" | A program of deliveries, not one delivery. Route per the task-type entry points to muuli:orchestrating-milestones. |
| "I'll just drop the report at the repo root" | Every artifact goes under the configured workflow base (`.muuli-workflows/` default, or `docs/muuli/`). |
| "The user writes Finnish, so the spec can too" | Artifacts are ALWAYS English — cheaper in tokens, unambiguous next to code. Only chat follows the user's language. |
| "The gate rejected it, so it's gone" | REJECT judges the proposal as written, not the backlog. Rejected findings appear in the deliverable for the user's drop/reinstate decision — never silently dropped. |
| "All lens agents were dispatched, so I have full coverage" | Subagents die silently on API errors. Verify every report file exists before gating. |
