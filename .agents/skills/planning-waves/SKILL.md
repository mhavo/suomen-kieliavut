---
name: planning-waves
description: Use when a spec is frozen and the implementation needs waves, plans, and a master tracker before any coding subagent is dispatched — or when creating, updating, or restructuring an implementation tracker, including one that will be driven by the ralph loop driver (ralph-tui.sh).
---

# Planning Waves

## Overview

One master tracker is the single state file for the delivery; plans are terse
briefs for a skilled coder. The tracker is machine-drivable: its checkboxes ARE
the execution state (ralph-compatible).

**REQUIRED BACKGROUND:** muuli:using-muuli (artifact locations, forced-skills
rule). Executed by muuli:supervising-waves.

## When to use

- A frozen spec exists (muuli:writing-specs) and coding is next.
- The delivery spans multiple waves or subagents.
- The plan may be fed to the ralph loop driver (`ralph-tui.sh PLAN.md`).

NOT for: a single small fix (direct TDD, no tracker) or bughunt logs
(`.muuli-workflows/BUGFIX.md` — see muuli:hunting-bugs).

## Master tracker — `.muuli-workflows/<date>-<series>/IMPLEMENTATION_TRACKER.md`

The tracker lives inside the delivery's dated series folder
(`<date>` = `date +%F`) together with its spec and wave plans — one portable
folder per delivery, no cross-delivery name collision. See muuli:using-muuli
"Naming". When you create the series folder, append its one-line pointer to
`<BASE>/INDEX.md` (create the index if missing) so the delivery is discoverable
from the base root.

**ALWAYS write the tracker (and every plan/brief) in English — regardless of
the conversation language.** No exceptions: even in a Finnish (or any non-English)
conversation, the tracker headings, tasks, gates, and notes are English. English
is cheaper in tokens and unambiguous next to code; only chat output follows the
user's language. See muuli:using-muuli "Language rule".

Create from `tracker-template.md` (in this skill's directory). Structure:

- **Executor header** (blockquote at top): names the skill that runs the plan
  — normally muuli:supervising-waves. The ralph loop driver reads this
  recommendation from the header.
- **Status legend**: `[ ]` not started · `[~]` in progress · `[x]` done ·
  `[!]` blocked.
- **Locked decisions + interface contracts at the top** — the things no wave
  may re-open (invariants, formats, IDs, API signatures). Number them
  (R1, R2, …) so specs, plans, and reviews can cite them.
- **Waves W0→Wn**, each with tasks as checkbox lines and an explicit **gate**:
  the commands that must pass and criteria that must hold before the next wave
  starts. Verification lives in the gate — at the END of the wave, never
  between tasks.
  **A mid-delivery gate's scope is the wave's own surface; the full suite is the
  delivery's LAST gate.** Write each wave's `Gate:` around the tests its file map
  can break — its own modules plus the callers of what it changed — run uncached
  by the supervisor. The full `Gate runner:` runs at three points only: the LAST
  wave's gate, any wave that CHANGES shared surface (an existing settings key,
  schema, build config, or a symbol most of the repo imports — adding a new one
  nothing yet reads is not that), and every gate in a repo
  whose suite is cheap enough that scoping it costs more thought than running it.
  Nothing else at the gate changes: same uncached self-run, same `Known-red
  baseline:` rule, and muuli:supervising-waves R4b's falsifying edits stay per
  task either way. A suite
  re-run per wave costs one full suite per boundary and learns nothing the last
  gate would not.
  **The completion condition's runnable proof is W0.** When the completion
  condition names something executable — a walkthrough script, an end-to-end
  scenario, a demo command, i.e. one artifact the gate can invoke by name; a
  condition that merely describes observable behaviour is not one — that
  artifact is authored in the FIRST wave,
  against the system that does not exist yet, and is expected to FAIL: W0's gate
  requires it to run and fail for the stated reason, never to pass. It runs as
  its own **named command**, kept out of the suite's verdict (skip or
  expected-fail marker — it must never make the suite red) until the wave that
  turns it green, so the suite and every other gate command still pass and the
  "commands that must pass" rule above is untouched.
  Every later wave drives it green. Scheduling it last means everything it finds
  returns as rework of waves already gated — the same cycle TDD prevents at task
  level, one altitude up. If it must assert against an artifact a later wave produces
  (a runbook whose steps it mirrors), its executable spine is still W0 and that
  one assertion is added by the wave that produces the artifact.
  **A wave owns the documentation of the surface it changes.** The doc files
  describing a wave's commands, error codes, routes or fields appear in THAT
  wave's file map and task list, and its gate checks them — never deferred to a
  single close stage. **Owning the documentation is not the same as adding a doc
  bullet.** The task says which HOME the fact gets, and the default home is the
  code: a fact true of ONE symbol goes in that symbol's docstring and the doc
  gets nothing — not a summary, not a "see also". Only a rule two modules
  enforce that neither owns earns a row in an `AGENTS.md`. The exception is a
  TRAP — a fact that changes which call a reader makes *before* opening the file
  — which may sit in both, with the doc's copy the SHORT one. Without this
  sentence the obligation reads as "edit the doc", the wave writes the fact
  twice (once in the JSDoc the code needs anyway), and **no gate can see it**:
  `drift` sees change, `coverage` sees absence, `tokens` sees size. The doubling
  surfaces years later as a budget overrun, which then charges a prune for it.
  `redundancy --staged` in the shipped pre-commit hook is the only check that
  catches the pair at the commit that creates it. Deferred doc work is found by the audit that runs before
  it (muuli:orchestrating-milestones S5 precedes S7), so every milestone spends
  a redteam slot, a gate ruling and a plan entry re-reporting staleness that was
  already scheduled. A doc file that belongs to a budgeted package
  (muuli:ai-docs) is owned by that same wave — the two rules never compete.
  A separate **ai-docs routing task is W0 work ONLY when the spec's new surface
  does not fit the installed routing**: it needs a new page or index entry, or
  its target page is already at its token budget. Sized from the spec, because
  discovering at the close stage that the budget is full is what forces a
  five-block emergency re-route. When the surface fits an existing page — the
  ordinary case — the wave's own doc edit is the whole obligation and no ai-docs
  task is scheduled; a full package UPDATE pass is never a routine stage of a
  delivery. Where ai-docs is installed (look for the manifest — the planner reads
  the repo freely; it is only the SUITE it never runs) and the
  delivery changed a documented surface, the LAST wave's gate runs the same
  checks S7 does — `tokens --budget` always, `drift` and `coverage` when a
  documented page or an enumerable surface changed (a new identifier inside an
  existing surface counts); commands per muuli:ai-docs. A passing check closes
  the delivery's ai-docs obligation; a failing one re-opens THAT wave with the
  fix re-dispatched to that wave's agent as a task and the gate re-run **once**
  (for `tokens --budget` the fix is one route pass; still over, the agent
  records the debt with `stamp --accept-budget` or splits the doc, per
  muuli:ai-docs — a gate that re-runs until green re-runs forever) — never a
  new wave, and never a full package pass for a page this delivery owns.
  (A milestone's S7 schedules a package pass only for what no single delivery
  owns — muuli:orchestrating-milestones.)
  Each wave heading also carries a **suggested model tier** from
  its difficulty (mechanical/boilerplate → cheaper; judgment-heavy → stronger)
  that the supervisor honors at dispatch — see `tracker-template.md`. This is
  where wave difficulty is assessed, so it is where the tier is set. A wave takes
  the tier of its HARDEST task. That task is `cheap` when it only transcribes a
  design already decided — its signature fixed in the interface contracts and no
  judgment left in the body; locked signatures alone never make judgment-heavy
  work cheap (a concurrency, core-algorithm or security-sensitive body stays
  `strong` however locked its signature). Uniform tiers across a delivery mean
  difficulty was never assessed: say in the tracker why the uniform tier is
  right on the `Tiers:` line above W0 (`tracker-template.md`), or fix it.
- **Wave count is the smallest the dependencies allow.** A boundary exists only
  where something genuinely gates what follows: an interface later waves call, a
  measurement that cannot run until an earlier wave wired its path, a migration
  later code assumes — but an interface the SPEC already froze is not one: its
  callers transcribe a decided signature, and their order inside a single wave is
  a task order, not a gate. A frozen signature alone never dissolves a boundary:
  where an earlier task must still SETTLE what sits behind it — the storage
  representation, the ordering or dedup rule, the error taxonomy the callers
  branch on — the callers depend on that decision, not on the signature, and the
  boundary stands.
- **From boundaries to wave count.** Work that is parallel and mechanical is ONE
  wave however many subsystems or languages it touches — the hub's "independent
  modules → run in parallel" makes those parallel-safe TASKS inside one
  sequential wave, never waves of their own. Docs, tests and review are never
  waves either: docs belong
  to the wave that changes the surface (above), verification is the gate, TDD
  slices live inside tasks. Before writing the tracker, state for each boundary
  what would break if the two waves were merged — the tracker's `Boundary:` line
  under each wave heading after W0 (`tracker-template.md`); a boundary with no
  answer is choreography, and choreography is paid twice — once by the gate the
  supervisor must run, once by the handoff between two agents that needed to be
  one. ONE
  wave is a legitimate outcome; never invent a second to justify the tracker —
  except that a completion condition naming a runnable proof forces two, one to
  observe it failing and one to drive it green (above).
  (`plan-convention.md`'s "split it into two tasks" is task altitude and does not
  reach up here.)
- **Gate environment**: a `Gate runner:` line (the literal full-uncached-suite
  command for this repo) and a `Known-red baseline:` line (pre-existing failures
  in code no wave touches). You leave both as placeholders — you never run the
  suite and cannot know either value; the first supervisor to run a gate fills
  them, and every later wave and session then READS them instead of re-deriving
  a split recipe or re-litigating an untouched red test.
- **Progress log table**: `| date | wave | gate ☑ | key notes |` — appended by
  the supervisor only, after verifying the gate itself.

### Ralph compatibility (hard requirements)

- **The target repo ROOT must be a git repository before the tracker is driven
  by ralph.** Ralph resolves its working directory by running
  `git rev-parse --show-toplevel` from the tracker's own directory; with no git
  ancestor it falls back to using `<BASE>/<date>-<series>/` itself as the cwd,
  and the entire build lands there — the coder scaffolds the project and runs
  `git init` inside the artifact folder instead of the real repo. Before
  handing off, confirm `git -C <target-root> rev-parse --show-toplevel`
  succeeds; if it fails, `git init` at the target root first. Source code always
  goes in the target repo's working tree — `<BASE>/<date>-<series>/` is
  workflow artifacts only (spec, tracker, plans, reports), never a code root or
  a nested `git init`.
- Every task is a top-level checkbox line `- [ ] …` / `- [x] …`. The file IS
  the state; ralph computes progress from these boxes and exits when all are
  checked. `[~]`/`[!]` correctly count as *pending* in ralph — never use any
  other completion mark than `[x]`.
- Ralph drives "the first unchecked `- [ ]` task", so order tasks in execution
  order within sequential waves. One commit per task.
- Under ralph, the session handoff goes to `<tracker>.handoff.md` (e.g.
  `.muuli-workflows/<date>-<series>/IMPLEMENTATION_TRACKER.handoff.md`) — see
  muuli:handing-off.
- Gate lines and prose must NOT be checkbox bullets (they would skew ralph's
  progress count); write gates as `Gate:` lines, not `- [ ] Gate:`.
- Compatibility is not a launch. Actually starting the driver on this tracker —
  worktree choice, preflight, Stop hook, tmux session, watch, handback — is
  muuli:launching-ralph-runs.

## Plan files — `.muuli-workflows/<date>-<series>/plans/`

Terse briefs per wave — *what / how / why for a skilled coder*, only the
hardest code pieces shown. Follow `plan-convention.md` (in this skill's
directory). Every plan names the **forced skills** the implementer must discover
and load first: TDD + the available language- AND task-specific specialist
skills (typescript-pro, golang-pro, python-pro, frontend-design, …).

## The "hardest piece" anchor

When spec/plan writing is delegated to subagents, each author must return one
**hardest-piece anchor**: the single technical core point the implementer must
not guess wrong. The supervisor carries these anchors into the dispatch briefs.

## Interop

If `superpowers:writing-plans` is present, borrow its task-decomposition and
interface-contract discipline — but keep muuli's precision rule: exact code for
the hardest pieces only, never the blanket "exact changed code" writing-plans
defaults to. Without it, this convention stands alone. See muuli:using-muuli
"Relationship to Superpowers".

## Red flags

| Thought | Reality |
|---|---|
| "Tracker goes in docs/" | `<BASE>/<date>-<series>/IMPLEMENTATION_TRACKER.md` (base = `.muuli-workflows/`, or `docs/muuli/` if that is the configured base). Never loose at the repo root. |
| "The repo root isn't git-initialized, ralph will manage" | Ralph falls back to the tracker's own folder as cwd and the build lands there with a nested `git init`. `git init` the target root FIRST; code never lives under `<BASE>`. |
| "One tracker at the top level for everything" | Each delivery gets its own dated series folder; the tracker lives inside it. |
| "I'll add a per-task review step" | Verification is the wave gate, at the END of the wave. |
| "The end-to-end proof goes last, once the pieces exist" | It is W0 and it fails there; later waves drive it green. A proof written last turns its own findings into rework of gated waves. |
| "Test criterion: proves the steps run in the documented order" | Unfalsifiable as written. Name the falsifying edit that reddens it; if you cannot, the assertion is on the wrong surface. |
| "The frontend just reads it from the options endpoint" | Name the field on the response model. If you cannot, the endpoint does not return it — a missing task in this wave, not a detail for the coder. Stubbed tests pass either way. |
| "Docs get updated at the close stage" | The wave that changes the surface owns its docs. The audit runs BEFORE the close stage and will report the staleness every single milestone. |
| "One wave per subsystem / per file group / per language" | A boundary is a dependency, not a subject area. Name what breaks if the two merge; if nothing does, they are one wave. |
| "Everything `strong`, to be safe" | Uniform tiers mean difficulty was never assessed. A wave whose hardest task only transcribes a decided design is `cheap`. |
| "Every wave gate runs the full suite" | Mid-delivery gates run the wave's own surface. The full `Gate runner:` is for the LAST wave, a shared-surface wave, or a suite too cheap to scope. |
| "ai-docs is installed, so the delivery needs an ai-docs stage" | Only when the new surface does not fit the installed routing or budget. Otherwise the wave's own doc edit is all of it, checked once at the last gate. |
| "Full code listings make the plan safer" | Token waste. Only the hardest pieces are shown. |
| "No code listings, so the plan is lean" | Prose is where plans actually grow. PLAN BLOAT CHECK: is the plan's PROSE longer than the code it describes? Measured: 1640 words of plan for a 60-line change. |
| "The plan should restate the tracker's constraints so it stands alone" | Cite them by number (R3). Self-containment means the coder can FIND every fact, not that every plan repeats it. |
| "Custom checkbox marks show nuance" | Only `[x]` means done. Anything else is pending to ralph — and to the supervisor. |
| "The conversation is in Finnish, so the tracker can be too" | The tracker is ALWAYS English — headings, tasks, gates, notes. Only chat output follows the user's language. |
