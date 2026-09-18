---
name: handing-off
description: Use when context is running low, a phase or wave boundary is reached with more work remaining, the user commands HANDOFF, a session is ending mid-project, or you are about to continue on a tired context.
---

# Handing Off

## Overview

Never continue on a tired context. Hand off at a phase or wave boundary
**before** compaction becomes imminent — not mid-wave, when state is
half-applied. The handoff is a self-contained brief: the next session must be
able to continue from `.muuli-workflows/HANDOFF.md` + the tracker + the specs
ALONE, with no conversation history.

## When to use

- Context running low at any phase.
- A phase or wave boundary reached with more work remaining.
- The user commands HANDOFF.
- Session ending mid-project, or you are about to push on with a tired context.

## Protocol

1. **Archive the current handoff first.** If `.muuli-workflows/HANDOFF.md`
   exists, move it to `.muuli-workflows/HANDOFF-<prev>.md` before overwriting.
   Both are committed — a handoff that only lives on disk cannot survive the
   context loss it was written for.
2. **Fill the template** in `handoff-template.md` (bare filename — the skill
   base dir is injected at load). Write it to `.muuli-workflows/HANDOFF.md` —
   or, when a loop driver is driving this session, to its path instead, in
   which case step 1 does not apply (see "Ralph loop compatibility": that file
   is overwritten in place, never archived). Step 3 applies either way.
3. **STOP.** Do not start new work on this context.

**Forced mid-wave handoff** (context ran out before the boundary): do not
leave state half-applied and undocumented. Commit or stash the partial work
with a clearly marked WIP message, mark the wave's task `[~]` in the tracker,
and make NEXT ACTION state exactly what is half-applied (files, commit/stash
ref, what remains). The boundary rule is the goal; this is the recovery path
when it is missed.

## Rules

- **ALWAYS English.** The handoff — every section, note, and NEXT ACTION — is
  written in English regardless of the conversation language. No exceptions.
  Only chat output follows the user's language (muuli:using-muuli "Language rule").
- **Facts only, no narration.** Every claim must be verifiable — commit shas,
  test counts, `file:line`. No "should be fine."
- **NEXT ACTION is the most valuable section.** Write it as if briefing a
  skilled colleague who has read nothing else — enough analysis that they do
  not re-derive it. If blocked on a user decision, state the exact question and
  your recommendation.
- **Record agent-history lessons** that change how the next agent should brief
  its subagents (e.g. "agent without exact signatures burned context
  exploring" → put signatures in the brief).

## Ralph loop compatibility

Under the ralph loop driver, ralph expects the handoff at `<plan>.handoff.md`
next to the PLAN/tracker file it was given (e.g.
`.muuli-workflows/<date>-<series>/IMPLEMENTATION_TRACKER.handoff.md`). Write
ralph's path and follow its marker protocol — the muuli HANDOFF template's
content shape applies either way. That file is gitignored and overwritten in
place each iteration (no archive step — the archive protocol above is for the
committed singleton), so anything that must survive the run belongs in the
tracker, not only in it. A loop-driven session writes ONLY ralph's path;
running the archive-then-write protocol once per iteration would litter the
base with `HANDOFF-<prev>.md` files. `<BASE>/HANDOFF.md` is for sessions no
loop driver is driving — including the one that stops the loop for good.

**A supervisor's handoff is a third file.** A session that LAUNCHED a loop and
watches it from outside writes neither of the above: its state (which gates it
verified and on what criterion, which of the run's claims it checked, what the
user answered) goes to `<BASE>/<project>-supervision-<date>.handoff.md`, so two
supervised programmes can coexist. Its content shape is
muuli:launching-ralph-runs' `supervisor-handoff-template.md`, not the template
here — the re-arming command comes first, because the watch died with the
context and nothing else in the file works until it is back.

See muuli:using-muuli for artifact locations; muuli:planning-waves for the
tracker; muuli:supervising-waves for the supervisor rules a handoff pins down.
