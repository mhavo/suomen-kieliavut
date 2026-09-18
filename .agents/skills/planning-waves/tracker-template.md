# Tracker template — `.muuli-workflows/<date>-<series>/IMPLEMENTATION_TRACKER.md`

Copy, replace `<…>`, delete comments — EXCEPT the `Gate environment` section,
whose two lines stay as placeholders until the first supervisor fills them, and
whose ownership note stays in the file until then. Keep every task a top-level `- [ ]`
checkbox line (ralph-compatible: the file IS the state).

```md
# <FEATURE> — IMPLEMENTATION TRACKER

> Executor: muuli:supervising-waves — waves are sequential, one implementing
> subagent per wave, verification at the wave gate (end of wave, never per
> task). Every coding brief forces TDD + the language skill.
> Spec: .muuli-workflows/<date>-<series>/SPEC.md
> Status legend: [ ] not started · [~] in progress · [x] done · [!] blocked
> (only [x] counts as done — ralph treats [~]/[!] as pending)

## Locked decisions (no wave may re-open)

- Completion condition (from V0, verbatim from the living draft): <the
  explicit condition the delivery must satisfy before stopping — becomes the
  supervisor's goal text in V5>
- R1: <invariant / format / ID / API signature — with WHY>
- R2: <…>

## Interface contracts

<Exact signatures every wave must respect. Dig them out now — an
underspecified API sent one agent into a 73-tool-call exploration spiral.>

## Gate environment (derived once, committed — never re-derived per wave)

Owner: the PLANNER leaves both lines as `<…>` — it never runs the suite and
cannot know either value. The FIRST SUPERVISOR that runs a gate derives and
writes them, and every later wave, milestone and session READS them instead of
re-deriving. (Keep this note in the tracker until both lines are filled.)


Gate runner: <the literal full-uncached-suite command line for THIS repo — run
at the LAST wave's gate, at any wave touching shared surface, and at every gate
where the suite is too cheap to bother scoping (muuli:planning-waves). If
the suite does not fit the shell timeout, foreground parts that do, plus the
enumeration cross-check (summed executed = whole-suite enumerated, nothing
deselected). Never backgrounded — a killed run reports no failure.>
Known-red baseline: <pre-existing failures in code no wave touches: file ·
test · reason · counts. Gates pass while this set is UNCHANGED; any new red,
changed reason or higher count fails. "none" if the suite is clean.>

## Waves

<!-- Delete this tracker's second wave unless a dependency earns it: one wave is
     a legitimate tracker, and then W0 IS the last wave (its gate takes the
     `Gate runner:` and the ai-docs clause shown under W1). A completion
     condition with a runnable proof always earns the second wave — W0 observes
     it failing, the last wave drives it green. -->
Tiers: <omit unless this tracker has two or more waves that all carry the same
tier — then say in one line why that is right>

### W0 — <name> · tier: <cheap|standard|strong>
<!-- W0 carries no `Boundary:` line — there is no previous wave to merge into.
     If the completion condition names a runnable proof, it is authored HERE. -->
- [ ] <task — concrete, testable, one commit>
- [ ] <task>

Gate: <scoped run: the tests this wave's file map can break — its own modules
plus the callers of what it changed — uncached, by the supervisor; use
`Gate runner:` instead when this wave touches shared surface, is the LAST wave,
or the suite is too cheap to scope> + <criteria: tests RAN (not skipped), working
tree clean, protected paths untouched, red set unchanged from `Known-red
baseline:`> + <docs: the doc files for every surface THIS wave changed are
updated in this wave's commits — omit only if the wave changes no documented
surface> + <falsifying edits: each task's named edit applied, its test module
observed RED, restored, green re-confirmed — a test still green under its own
falsifying edit fails this gate>
<!-- Plus, at W0 when a runnable proof exists: `<the named proof command>` RUNS
     and FAILS for the stated reason (name it), and the suite above still
     passes (the proof is excluded from its verdict). Later waves narrow that
     reason; the wave that turns the proof green folds it into the suite's
     verdict — a proof that passes early fails the gate. -->

### W1 — <name, the LAST wave here> · tier: <cheap|standard|strong>
Boundary: <what breaks if this wave is merged into W0 — the interface it fixes,
the measurement it enables, the migration it lands. No answer means it is not a
wave: merge it.>
- [ ] <task>

Gate: `Gate runner:` above passes (the delivery's full uncached suite runs HERE)
+ <the same criteria as W0> + <ai-docs, only where the repo has an
ai-docs manifest and this delivery changed a documented surface:
`tokens --budget` green, plus `drift`/`coverage` where a documented page or an
enumerable surface changed — a new identifier inside an existing surface counts>

## Progress log (supervisor only, after verifying the gate itself)

| date | wave | gate ☑ | key notes |
|---|---|---|---|
```

Rules:

- ALWAYS write the tracker in English — every heading, task, gate, and note —
  whatever language the conversation uses. No exceptions (see muuli:using-muuli
  "Language rule").
- Gates are `Gate:` prose lines, NEVER checkbox bullets — checkboxes are
  reserved for tasks so ralph's progress count stays truthful.
- **Density** (muuli:using-muuli "Density rule"): a task is ONE line — one
  commit's worth of work, no sub-bullets, no rationale. Progress-log notes are
  one line. What is NOT compressed: locked decisions keep their WHY, interface
  contracts keep full signatures, the completion condition stays verbatim, and
  `Gate:` keeps all its criteria — "dig them out now" still applies, it just is
  not a licence to over-specify.
- The `· tier:` suffix on each wave heading is the planner's model-tier
  recommendation from that wave's difficulty (mechanical/boilerplate → `cheap`,
  ordinary → `standard`, judgment-heavy: core algorithm, concurrency,
  security-sensitive → `strong`). A wave takes the tier of its HARDEST task, and
  that task is `cheap` only when it transcribes a decided design — signature
  locked above AND no judgment left in the body; a concurrency, core-algorithm or
  security-sensitive body stays `strong` however locked its signature. Uniform
  tiers across the delivery need a stated reason.
  `standard` means the session's inherited default model; a wave heading that omits the `· tier:` suffix is treated as
  `standard`. It is prose in the heading, not a checkbox, so ralph's progress
  count is unaffected. The supervisor honors it at dispatch; the gate is
  verified by the supervisor itself and is never downgraded.
- Wave count is the smallest the dependencies allow: every wave after W0 carries
  a `Boundary:` line naming what breaks if it is merged into the previous one,
  and a wave that cannot fill it is merged instead (muuli:planning-waves). One
  wave is a legitimate tracker. `Boundary:` and `Tiers:` are prose lines, never
  checkboxes.
- Only the supervisor updates this file, after running the gate itself.
- Under ralph: handoffs go to
  `.muuli-workflows/<date>-<series>/IMPLEMENTATION_TRACKER.handoff.md`
  (ralph's `<plan>.handoff.md` convention — see muuli:handing-off).
