# Hardening Notes

Two committed locations (both survive a fresh clone; see muuli:using-muuli
"Artifact location"; never the repo root):
- **Per-delivery** `<BASE>/<date>-<series>/HARDENING_NOTES.md` — findings
  specific to THIS delivery; the series folder is the delivery tag. Written by
  a delivery's V3 spec loop, read first by its V6 audit. This is the default.
- **Cross-cutting** `<BASE>/HARDENING_NOTES.md` — only package-/codebase-/
  threat-model-wide defers and rejects that must suppress red-team noise ACROSS
  deliveries. Read by whole-repo audits and by muuli:improving-skills (which has
  no series folder).

Both persist across runs, unlike the gitignored per-run audit reports beside
them.

Deferred or rejected red-team findings that should not bloat the current spec.

This document is loop memory. It prevents the red-team reviewer from re-raising
known non-spec concerns every iteration while preserving useful hardening ideas
for future work. It lives for the whole lifecycle: the spec loop writes it, the
audit loop reads it first.

Rules:
- **One line per field**, and a stable title. If an entry needs a paragraph it
  belongs in the spec or an ADR, not here.
- Do not turn this file into a second spec.
- Prefer one entry per recurring concern or future hardening idea.
- Enough context for a future reviewer to RECOGNISE the item and not re-raise
  it — that is a one-line identification, not a re-argument of the case.
- Re-open an item only if the product scope, implementation, or threat model
  changes.

## Deferred Hardening Ideas

Valid concerns that may become worth addressing later, but should not expand
the current spec.

### [Short Stable Title]

- Concern:
- Why not in spec now:
- Future trigger:
- Smallest future mitigation:
- Source iteration/date:

## Rejected / Already Covered Patterns

Findings that are unrealistic, already handled by existing guarantees, or
outside the product boundary. These entries exist mainly to suppress repeated
red-team noise.

### [Short Stable Title]

- Claim:
- Rejection reason:
- Existing guarantee or boundary:
- Do not re-raise unless:
- Source iteration/date:

## Reinstated by User Decision

Rejected findings the user overrode into the implementation backlog. Do not
re-raise as new findings AND do not treat as suppressed — they are planned
work. One line each: item → plan/tracker reference.

## Open Questions — end-of-program batch

Unanswered questions parked by an unattended run, NOT findings: they suppress
nothing, and a reviewer who independently finds the same thing reports it
normally. Each is asked once, as a batch, when the program's completion
condition is otherwise met (muuli:orchestrating-milestones). One line each:
question → recommendation → what raised it. Delete an entry once answered.
