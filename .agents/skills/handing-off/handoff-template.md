# HANDOFF template (context-change protocol)

Written to `.muuli-workflows/HANDOFF.md` (committed — see muuli:using-muuli
"Committed by default and `.gitignore`"; never the repo root) when context runs
low, the phase changes, or the user commands HANDOFF. The next session must be
able to continue from this file + the tracker + the specs ALONE. Archive the
previous HANDOFF (e.g. `.muuli-workflows/HANDOFF-<prev>.md`) before overwriting.
Under a loop driver the destination is `<tracker>.handoff.md` instead and there
is no archive step — this content shape is unchanged (muuli:handing-off "Ralph
loop compatibility").

```md
# HANDOFF — <feature/task> <role, e.g. wave supervisor>

> For the next <role> agent. Continue driving
> `.muuli-workflows/<date>-<series>/IMPLEMENTATION_TRACKER.md` from where this stopped.
> Branch: <branch>. Date: <date>. HEAD at handoff: <sha> — the successor's
> freshness test is `git log <sha>..HEAD --oneline`; anything there means this
> file is stale.

## Role (do not deviate)

<The operating rules verbatim — for a supervisor, the seven rules from
muuli:supervising-waves, with project-specific gate specifics baked in.>

## Gate verification (run YOURSELF for every wave)

<Cite the wave's own `Gate:` line for the scope to run, plus the tracker's
`Gate runner:` and `Known-red baseline:` lines — do not restate them here. The
full runner is the LAST wave, a wave changing shared surface, or a suite too
cheap to scope (muuli:planning-waves). This file is gitignored under a loop driver, so anything
recorded ONLY here is re-derived by every later session; that is exactly why
both facts live in the committed tracker. If the tracker has no such lines yet,
write them there first, then cite. Environment prep that is genuinely
session-local still belongs here.>

## Environment notes (tell EVERY agent)

<Env quirks: broken/stale env vars and the exact fix; known-dirty working-tree
files that are not this task's code; tooling that is unavailable to subagents
and what to provide instead (e.g. exact API signatures in the brief).>

## Wave status

| Wave | Status | Commits |
|------|--------|---------|
| W0 <name> | ✅ done+verified / ⚠ blocked / [~] in progress | <shas> |

## DONE this session

<Numbered list: what was completed, verified how, which commits, which tracker
rows were updated.>

## NEXT ACTION

<The single most important next step, with enough analysis that the next agent
does not re-derive it. If blocked on a user decision, say exactly what
question to re-surface and what the recommendation was.>

## API signatures / interfaces the next agent will need

<Exact signatures dug out and verified — the next agent must not guess or
re-explore these.>

## Locked contracts

<Pointer to the tracker's locked-decisions section + any invariant numbers
that constrain the remaining work.>
```

Rules:
- ALWAYS write the handoff in English — every section and note — whatever
  language the conversation uses. No exceptions (see muuli:using-muuli
  "Language rule").
- Facts only, no narration. Every claim verifiable (commit shas, test counts,
  file:line).
- Record agent-history lessons that change how the next agent should brief
  (e.g. "agent without exact signatures burned its context exploring").
- The NEXT ACTION section is the most valuable part — write it as if briefing
  a skilled colleague who has read nothing else yet.
