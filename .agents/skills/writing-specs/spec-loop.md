# Spec Loop — isolated redteam ⟷ Realism Hat

Run an isolated adversarial review loop against a spec while keeping the spec
pragmatic, shippable, and maintainable. The two-hat structure is mandatory:
redteam alone bloats specs (documented: ~23 rounds, 170K-token spec when every
finding was applied directly).

Replace:
- `[SPEC]` — spec file path. During V3 this is the living draft
  (`.muuli-workflows/<date>-<series>/FEATURE.md`); it is frozen to
  `.muuli-workflows/<date>-<series>/SPEC.md` only after the loop stops.
- `[HARDENING_NOTES]` — hardening notes paths. This loop WRITES to the
  delivery's own `<BASE>/<date>-<series>/HARDENING_NOTES.md` (committed
  in-folder; create from `hardening-notes-template.md` if missing); it also
  READS the cross-cutting `<BASE>/HARDENING_NOTES.md` so package-wide rejects are
  not re-raised. See muuli:using-muuli "Artifact location".
- `[REVIEWER]` — `codex exec --sandbox workspace-write "<prompt>"` if codex CLI
  exists; otherwise a fresh clean-context subagent given the same prompt. The
  reviewer must NOT share your conversation history.
- `[DOMAIN_RISKS]` — the project's real risk surface, e.g. "state transitions,
  crash recovery, persistence consistency, async workflows, user-visible data
  loss, security boundaries, integration with existing code". Name the actual
  subsystems.

## The loop

```md
Read:
- [SPEC]
- [HARDENING_NOTES]

If [HARDENING_NOTES] does not exist, create it from the hardening notes template.

Then run [REVIEWER] as an isolated adversarial critic:

"
Read:
- [SPEC]
- [HARDENING_NOTES]

Act as an adversarial red-team critic.

Your job is to find concrete ways this spec could fail in the real codebase.
Focus on risks introduced by OUR design: [DOMAIN_RISKS].

Do not repeat findings already captured in [HARDENING_NOTES], unless the spec
has changed in a way that makes the old concern newly material.

Do not invent apocalypse scenarios.

Assumptions:
- The CPU, kernel, filesystem, database ACID behavior, and normal platform APIs
  generally work as documented.
- Existing mature dependencies generally keep their contracts.
- We are designing an application, not an operating system.
- A finding must be actionable within this product's architecture.

Ponytail rule:
Prefer deletion, narrowing, existing invariants, existing repo patterns,
database constraints, and platform guarantees over adding new state, protocols,
services, locks, retries, watchers, or recovery machinery.
If your proposed fix adds a new mechanism, justify why a smaller clarification,
test, invariant, or existing guarantee is insufficient.

For each finding, include:
- Severity: CRITICAL / SEVERE / MINOR / COSMETIC
- Failure mode: the exact thing that goes wrong
- Trigger: the concrete sequence of events or inputs that causes it
- Impact: what the user or system loses
- Evidence: cite [SPEC] lines and/or repo files/lines
- Minimal fix: the smallest spec change that would address it
- Scope check: why this belongs in the spec rather than HARDENING_NOTES, tests,
  operational docs, implementation detail, platform guarantees, or future work

Reject your own weak findings. If you cannot cite evidence or describe a
concrete trigger, do not include the finding.

Keep each field to one or two lines — evidence as citations, not quoted
passages. Do not list findings you self-rejected: a self-rejected finding is
not a finding.

Analyse at most 8 findings per round in full, highest severity first. **Never
withhold a CRITICAL or SEVERE finding** — if more than 8 reach that bar, report
them all. Anything left over goes in the SAME file under a final
`DEFERRED — NOT ANALYSED THIS ROUND` heading, one line each: there is no other
carrier — you are a fresh reviewer each round and this file is deleted after
it is read.

Write feedback to .muuli-workflows/<date>-<series>/spec-loop/redteam.md (ephemeral working dir,
gitignored — never the repo root).
Do not modify anything except .muuli-workflows/<date>-<series>/spec-loop/redteam.md.

If the spec is solid, write exactly:
NO MATERIAL FINDINGS
"

Now act as the primary agent wearing the Realism Hat.

You are a pragmatic tech lead. Your job is not to satisfy the red-team. Your
job is to keep the spec correct, useful, shippable, and maintainable.

Read .muuli-workflows/<date>-<series>/spec-loop/redteam.md and classify every finding:

ACCEPT INTO SPEC:
- real possibility of data loss
- unrecoverable or incorrectly recoverable state
- security boundary violation
- contradiction with existing code or documented invariants
- state-machine ambiguity that implementers would reasonably get wrong

MOVE TO HARDENING_NOTES:
- valid concern, but not needed for the first implementation
- useful future hardening idea
- test idea or operational check
- implementation caution that should not expand the spec
- real but too expensive or broad for current scope

REJECT:
- depends on OS/DB/filesystem primitives breaking their documented contract
- asks us to defend against every possible concurrent or cosmic failure
- adds machinery without changing the user-visible safety story
- duplicates a deferred or rejected finding already in [HARDENING_NOTES]
- true in theory but outside the scope of this product

For accepted findings: update [SPEC] with the smallest precise change.
For hardening findings: append to [HARDENING_NOTES] (concern, why deferred,
future trigger, smallest future mitigation; no duplicates).
For rejected findings: do not touch [SPEC]; add to [HARDENING_NOTES] only if
likely to recur and worth suppressing in future loops.

After processing:
1. Delete .muuli-workflows/<date>-<series>/spec-loop/redteam.md.
2. Print an iteration report — **one line per item, no restated rationale**
   (a form rule, never a length cap: completeness of the REJECTED list wins
   over brevity every time):
   - ACCEPTED INTO SPEC
   - MOVED TO HARDENING_NOTES
   - REJECTED — list each rejected finding with its rejection reason; the
     iteration report is where spec-loop rejects are surfaced for the user,
     never drop one silently
   - SPEC BLOAT CHECK: are we making the design heavier than the product risk
     justifies?
   - SPEC SIZE: `wc -w [SPEC]` before and after this round, against the count
     of **locked decisions + invariants + edge cases** gained (all three are
     spec content — counting decisions alone would flag an honest edge-case
     round as bloat). Words up while ALL of those stay flat means you added
     rationale prose, not spec — cut the prose back to one line of WHY per
     decision before the next round. Never cut a decision, invariant, or edge
     case to make the number look better. The loop only ever adds; this is the
     only step that removes.
3. Run the loop again.

Stop when:
- .muuli-workflows/<date>-<series>/spec-loop/redteam.md says NO MATERIAL FINDINGS
- all remaining findings are COSMETIC/MINOR with no product-safety impact
- all remaining findings are already captured in [HARDENING_NOTES]
- or the Realism Hat rejects all remaining findings as unrealistic,
  already-covered, or wrong-scope.
```

## Scaling

- Safety-critical work (data loss, security invariants): full loop to a stop
  condition, external reviewer preferred.
- Ordinary feature: 1–2 rounds with a clean-context subagent as reviewer. The
  round cap beats the `Stop when` conditions: at the cap, move remaining
  findings to [HARDENING_NOTES] and stop — only a real data-loss or
  security-boundary finding justifies another round.
- If the spec bloated anyway — trigger: SPEC SIZE grew across rounds without a
  matching gain in locked decisions — lean distillation in a clean context: a
  handoff prompt produces a
  lean spec + ADRs. No decision, invariant, or edge case may be dropped;
  rationale prose moves to ADRs and does not survive in the spec.
