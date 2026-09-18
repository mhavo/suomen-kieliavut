# Plan convention — terse briefs for a skilled coder

Plans ALWAYS live in the delivery's series folder `plans/` subdir
(`.muuli-workflows/<date>-<series>/plans/W*-*.md`) — never in `specs/`.
Per-wave sub-specs (`.muuli-workflows/<date>-<series>/specs/W*-*.md`) share the
`W*-*.md` name pattern; the `plans/` vs `specs/` subdir is what tells a plan
from a sub-spec, and the dated series folder keeps a re-used feature name from
colliding (see muuli:using-muuli "Naming"). The master tracker convention
lives in `tracker-template.md`.

Plans are **concise instructions for a skilled coder — what, how, why**. NOT
full code listings (token waste). Each plan contains:

- **Title + forced skills** — name the skills the implementer must discover and
  load first: TDD + the available language- AND task-specific specialist skills
  for its language/stack and task (e.g. typescript-pro, golang-pro, python-pro,
  react-expert, frontend-design/design, a testing skill). Repeat this in the
  dispatch brief too, and require the coder to check what is installed.
- **Goal** — 1 sentence.
- **Architecture** — 2–3 sentences.
- **Global constraints** — toolchain/versions, plus the tracker's locked
  contracts and numbered invariants that apply, **cited by number** (see the
  no-restatement rule below).
- **File map** — a **table, one row per file**: path · created/modified/read · its
  one responsibility (line numbers where relevant). **Open every existing file
  before writing its row, and give every surface the wave READS but does not
  write a row of its own** — the route, DTO or module it consumes — naming the
  symbol that produces each value the tasks below promise. A promised value
  with no named producer is missing wave scope, not a coding detail: the
  consuming wave stubs that surface in its own tests, so its falsifying edit
  reddens against the stub, the gate passes, and it ships as dead code.
- **Tasks as vertical slices** — each with *what / how / why* + a **test
  criterion** + its **falsifying edit**. No ready-made test code unless it is
  the hardest piece. **Budget: 1 line what, 1–2 lines how, 1 line why, 1 line
  test criterion, 1 line falsifying edit.** Name the cases the test proves; do
  not pre-write the test matrix in prose.
  The **falsifying edit** is the one-line change to PRODUCTION code that must
  turn this task's test red — "swap the two entries in the ordered-steps
  constant", "delete the early return that short-circuits the no-write mode".
  It exists because "what the test
  proves" is a restatement of the guarantee by construction: it is satisfied
  by a test that cannot fail, and the wave gate then passes that test green,
  ran, and worthless (muuli:supervising-waves R4b runs this edit at the gate).
  **If you cannot name the edit, the assertion is on the wrong surface** —
  pick an observable whose VALUE differs between the implemented and
  unimplemented states (the emitted step order, the kwarg actually received,
  the error code raised), never an end state that is identical either way.
- **Do not restate the tracker.** Locked decisions and interface contracts live
  in the tracker — cite them by number (R3), never copy them into every plan.
- **Only the hardest code pieces** shown as examples (the tricky reduce, the
  atomic snapshot, the hash computation).
  **Precision scales with difficulty:** show exact code only where the change is
  genuinely hard.
- **No placeholders** — no "TBD" / "handle edge cases". Every task concrete
  and testable. **Shorter never means vaguer:** if a task does not fit the
  budget, split it into two tasks — never blur it.
- **PLAN BLOAT CHECK** — is the plan's PROSE longer than the code it describes?
  A wave plan for a 60-line change should not carry 800 words of prose. Shown
  hardest-piece code and file-map rows do NOT count toward that figure — both
  are required content, and precision always wins over the word count.
  Density style: muuli:using-muuli "Density rule".
- **Review at the wave gate, not per task.** Commit frequently (TDD cycle per
  slice).
