---
name: supervising-waves
description: Use when executing an implementation tracker or plan that has multiple waves via coding subagents — a feature delivery entering the coding phase after specs and plans already exist. Not for a single small fix.
---

# Supervising Waves

## Overview

The wave supervisor **does not code**. It briefs one implementing subagent per
wave, verifies each wave's gate ITSELF (uncached), updates the tracker, and
hands off cleanly. Read `wave-supervisor.md` — it holds the goal-prompt
template and the seven rules; set it as the session goal for a delivery.

Prerequisite: `.muuli-workflows/<date>-<series>/IMPLEMENTATION_TRACKER.md` and per-wave
spec/plan artifacts exist (from muuli:planning-waves).

## When to use / not

- **Use** — a multi-wave tracker to execute via subagents; a feature delivery
  in the coding phase (V5) after specs and plans are frozen.
- **Not** — a single small fix or one-file bug: do direct TDD, no supervisor.

## The seven rules (checklist)

Full text in `wave-supervisor.md`. In order:

1. Waves run **sequentially** — never start wave N+1 before N's gate verifies.
2. One implementing subagent per wave (general-purpose, named `wave-*`), **at
   the model tier the tracker's wave heading assigns** (the `· tier:` suffix,
   `cheap`/`standard`/`strong`) — mechanical/boilerplate waves run fine on a
   cheaper model (Sonnet/Haiku), judgment-heavy waves get the strong one;
   default only when the tier is unset. Your own gate verification (R4) never
   downgrades.
3. **[R3] Every brief forces the agent to discover and load the available
   language- AND task-specific specialist skills** — typescript-pro, golang-pro,
   python-pro, react-expert, frontend-design/design, testing skills, … — **plus
   TDD, by name, LOADED before coding.** Not just a fixed language list: the
   agent checks what is installed for its language/task and loads those too.
   Repeat this in the brief even when the spec already names them. Include
   [ENV_NOTES] and EXACT API signatures.
4. **[R4] Verify at the WAVE GATE, at the END of the wave — NEVER between
   tasks.** Per-task review is the documented superpowers failure mode muuli
   exists to avoid. Run the gate commands YOURSELF, uncached; never trust an
   agent's "all green". **Run the scope the wave's `Gate:` line names** —
   mid-delivery that is the wave's own surface, not the whole suite; the full
   `Gate runner:` belongs to the LAST wave, to any wave touching shared surface,
   and to repos whose suite is too cheap to scope (muuli:planning-waves). A wave
   whose gate names no scope gets the full runner.
   Run the wave's tests verbosely, confirm they RAN (not
   skipped), check git log, tree cleanliness, and untouched protected paths.
   Where the wave changed a documented surface, its gate also requires the doc
   files for the surface it changed to be updated in its own commits — docs deferred
   past the wave are found by the audit that runs before the close stage
   (muuli:planning-waves).
   A gate may name an **expected-failure** command — the completion condition's
   runnable proof, kept out of the suite's verdict until the wave that turns it
   green (muuli:planning-waves). There, verify the failure REASON matches the one
   the gate names; any other failure fails the gate, and so does the proof
   passing early. A red suite never passes a gate — only that one named command,
   and the tracker's recorded **known-red baseline**, may be red (below).
   **[R4b] Green is not proof.** Every criterion above is satisfied by a test
   that passes with the implementation deleted, and "I observed RED first" is
   the claim R4 forbids you to trust — that RED died in the agent's context. So
   apply the **falsifying edit each task's test criterion names**
   (muuli:planning-waves `plan-convention.md`), re-run that task's test module,
   require RED, restore, re-confirm green. Still green under its own falsifying
   edit = gate FAILS; re-dispatch the wave to assert an observable that DIFFERS
   between the two implementations, not an end state identical either way.
5. Gate verified → update the tracker (checkboxes + progress-log row). Only
   then start the next wave.
6. The agent never updates the tracker; the supervisor does, post-verification.
7. Told HANDOFF / context low / phase change → muuli:handing-off, then STOP.

## Two gate facts that belong in the tracker, not in your head

Derived once by the first supervisor that needs them, written to the
**committed** tracker (muuli:planning-waves `tracker-template.md`) — the handoff
is gitignored, so a fact parked only there is re-derived by every later wave,
milestone and session. Once written, later waves RUN these; they do not
re-invent them.

- **`Gate runner:`** — the literal full-uncached-suite command line HERE, run at
  the LAST wave's gate and at any wave touching shared surface; earlier waves gate
  on their own scope. If the
  suite does not fit your shell's timeout, split it into **foreground** parts
  that do, and cross-check: executed counts summed across parts must equal what
  the whole suite ENUMERATES (`pytest --collect-only`, `go test -list .`,
  `cargo test -- --list`, or verbose test ids where the stack has no list mode),
  nothing deselected. Never background a long suite to dodge the ceiling. Both
  a killed background run and a split that silently drops a directory look
  exactly like a passing suite.
- **`Known-red baseline:`** — pre-existing failures in code no wave touches
  (file, test, reason, counts). Without it R4's "nothing else may be red" has no
  compliant path and the same untouched failure is re-litigated at every gate.
  With it the rule is mechanical: the gate passes while the red set is IDENTICAL
  to the baseline; any new red, changed reason or higher count fails. Recording
  it is a one-time job — asking the user to fix untouched code mid-run is not a
  gate decision.

## Dispatch brief — minimum contents

XML skeleton (see muuli:using-muuli). Per wave: objective (what + why);
spec/plan paths to read; forced skills (R3); locked contracts + invariants;
exact API signatures; [ENV_NOTES]; verification commands the agent runs during
TDD; gate success criteria; model tier for the dispatch (from the wave heading,
R2). Self-contained — the agent has no history.

## Escalation

A wave surfacing out-of-scope or safety-critical work → do NOT do unsupervised
surgery. Document the blocker in the tracker, ask the user for a scope
decision, and continue with unblocked waves meanwhile.

## Interop

If Superpowers is present, this supervisor composes with it: dispatched agents
may use `superpowers:executing-plans` / `subagent-driven-development` to run a
plan, and `requesting-code-review` at a gate. Muuli keeps ownership of the wave
gate (verified by the supervisor itself, at the END of the wave) and forbids
per-task review — the failure mode it exists to avoid. Without Superpowers the
seven rules stand alone. See muuli:using-muuli "Relationship to Superpowers".

## Red flags

| Thought | Reality |
|---|---|
| "I'll review after each task" | Review at the WAVE GATE, at the end of the wave (R4). Per-task review is the failure mode. |
| "The agent reported all green" | Run the gate YOURSELF, uncached — agents report green from stale caches (R4). |
| "Green, uncached, tests RAN — the gate is satisfied" | All of that is true of a test that passes with the implementation deleted. Apply the task's falsifying edit and require RED (R4b). |
| "The agent says it observed RED before writing the code" | That RED died in its context. The only RED that gates a wave is one you produced yourself. |
| "The suite times out, I'll run it in the background" | A killed background run reports no failure. Foreground parts under the ceiling + the stack's enumeration cross-check, written to the tracker as `Gate runner:`. |
| "A test unrelated to this delivery is red, I must ask the user" | Record it once as `Known-red baseline:` and gate on the red set being unchanged. Untouched code is not a wave decision. |
| "The agent can start right away" | Not before its brief forces the language- + task-specific skills it discovers and loads, plus TDD, by name (R3). |
| "I'll dispatch every wave on the default model" | Tier the model to the wave's difficulty (R2). Mechanical/boilerplate waves run fine on Sonnet/Haiku; reserve the strong model for judgment-heavy waves and your own gate. |
| "Every wave gate means the full suite" | Mid-delivery gates run the wave's own surface, uncached, by you. The full `Gate runner:` is the LAST wave, a shared-surface wave, or a suite too cheap to scope. Scoping a gate is not deselecting inside a run that claims to be whole. |
| "Context is long but I can push on" | muuli:handing-off, then stop. |
| "The conversation is in Finnish, so the tracker/brief can be too" | Tracker updates, subagent briefs, and handoffs are ALWAYS English — only chat output follows the user's language. |

After all waves gate clean → muuli:auditing-code (V6).
