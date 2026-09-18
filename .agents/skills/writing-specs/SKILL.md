---
name: writing-specs
description: Use when writing or reviewing a spec or design doc for a feature before implementation planning, when a spec keeps growing round after round, or when confirming a bug's root cause before fixing it. Also when deciding whether a design is heavier than the product risk justifies, or a redteam review keeps producing findings you're tempted to apply directly.
---

# Writing Specs

**REQUIRED BACKGROUND:** muuli:using-muuli (phases, artifact locations,
`[REVIEWER]` fallback, XML brief skeleton).

## Overview

A spec is the implementing subagents' ONLY source of truth. Harden it by pairing
an **isolated redteam** ("this fails and isn't safe") with a **Realism Hat**
("you built a doomsday OS to move a file"). The gate is mandatory: redteam alone
bloats specs — documented failure of ~23 rounds and a 170K-token spec when every
finding was applied directly. Truth is at the intersection.

## When to use / when not

- **Use** for feature deliveries (V2 spec → V3 loop) and to confirm a bug's
  root cause before fixing when the cause is still uncertain or the fix spans
  enough surface that a separate confirmation step would reduce risk.
- **Skip the spec** for fixbug/bughunt/audit where issue text suffices — but
  fixbug still needs root-cause evidence before patching (see below).

## V2 — The spec convention

- **Living draft:** `.muuli-workflows/<date>-<series>/FEATURE.md` while you
  iterate (V0 may already have seeded it with the completion condition).
  `<date>` = `date +%F`; the whole delivery lives in this one folder — see
  muuli:using-muuli "Naming".
- **Frozen spec:** `.muuli-workflows/<date>-<series>/SPEC.md`. Multi-wave
  features split into per-wave sub-specs
  `.muuli-workflows/<date>-<series>/specs/W*-*.md`.
- A spec states **what + why**, numbered design decisions (§), edge cases, and
  locked invariants (R-numbered). No debate, no history — those go to ADRs.
- **Density** (muuli:using-muuli "Density rule"): **one line of WHY per
  decision or invariant** — longer rationale is an ADR, not spec body. Edge
  cases as a table, one row each. The spec carries the decisions; it is not the
  argument for them. **The size test is a ratio, not a length** (it applies from
  V3 on, once there is a previous round to compare against): words up while
  locked decisions, invariants, AND edge cases all stay flat means you added
  rationale prose, not spec — the spec-loop iteration report measures it each
  round. Do not compare the spec against the code; at V2 that code does not
  exist yet.

## V3 — Run the spec loop

Follow **spec-loop.md** (in this skill's directory) — isolated `[REVIEWER]`
redteam writes ephemeral findings; you wear the Realism Hat and classify each
into ACCEPT INTO SPEC / MOVE TO HARDENING_NOTES / REJECT. The loop runs on the
**living draft** (`<date>-<series>/FEATURE.md`); when it reaches a stop
condition, freeze the result as `<date>-<series>/SPEC.md`. After freezing, the
spec changes only
through a new loop round. The delivery's `<date>-<series>/HARDENING_NOTES.md`
is loop memory (template: **hardening-notes-template.md**), committed in-folder
and read first by the V6 audit loop — deferred/rejected items are never
re-litigated. Package-wide rejects that recur across deliveries go to the
cross-cutting `<BASE>/HARDENING_NOTES.md`.

**Scaling:**

- Safety-critical (data loss, security invariants): full loop to a stop
  condition, external reviewer preferred.
- Ordinary feature: 1–2 rounds with a clean-context subagent (the round cap
  beats the loop's convergence conditions — see spec-loop.md "Scaling").
- Spec bloated anyway → lean distillation in a clean context: decisions-why into
  ADRs, debate removed. **No decision, invariant, or edge case may be dropped —
  rationale prose moves to ADRs and does not survive in the spec.** Trigger:
  the spec grew across loop rounds without a matching gain in locked decisions
  — the SPEC SIZE line in spec-loop.md's iteration report measures exactly this.

**fixbug variant:** root-cause confirmation only — a failing test or trace
proving the *cause*, not the symptom. For a single known failing test or
surgical bug, this is the direct fix protocol in `muuli:using-muuli`, not a
reason to load this skill or write a full spec.

## Supplementary challengers (not every task)

- **Pre-mortem** for big directional decisions, ending in user-approved locked
  decisions.
- **Three-perspective heuristic:** user + clean subagent + external reviewer;
  ≥2/3 agree → treat as real.

**Interop:** if `superpowers:brainstorming` is present, run it first to explore
intent and requirements, then bring its output into this spec; without it, the
living draft → spec loop below already covers that ground. See muuli:using-muuli
"Relationship to Superpowers".

Next phase: muuli:planning-waves. Low on context → muuli:handing-off.

## Red flags

| Thought | Reality |
|---|---|
| "Redteam found it, so fix it" | Every finding passes the Realism Hat first — direct-apply is the documented bloat path. |
| "Spec needs one more mechanism" | BLOAT CHECK: is the design heavier than the product risk justifies? |
| "Each invariant deserves a paragraph of rationale" | One line of WHY per decision. Longer rationale is an ADR — the spec carries decisions, not the argument. Measured: rationale prose was 60% of a probe spec's largest section. |
| "The loop only accepts findings, so the spec only grows" | Words up while decisions, invariants AND edge cases all stay flat = added prose, not spec. The SPEC SIZE line in the iteration report is where you cut the prose back — never the content. |
| "This concern came up again" | Check HARDENING_NOTES first — deferred/rejected items don't get re-raised. |
| "I'll harden against every failure" | A finding must be actionable in this product's architecture; platform contracts hold. |
| "Fix the symptom" (fixbug) | V3 demands a test or trace proving the root cause. |
| "The user writes Finnish, so the spec can too" | Specs, living drafts, and HARDENING_NOTES are ALWAYS English — only chat output follows the user's language. |
