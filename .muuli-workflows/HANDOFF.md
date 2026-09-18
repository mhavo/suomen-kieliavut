# HANDOFF — clean-slate installation testing, implementer

> For the next implementer agent. Continue the delivery
> `.muuli-workflows/2026-09-18-clean-slate-testing/`.
> Branch: `main`. Date: 2026-09-18. HEAD at handoff:
> `5ba6547eb882d0c274a95916067fd9899c9aafd5` — the successor's freshness test
> is `git log 5ba6547..HEAD --oneline`; anything there means this file is stale.

## Process budget (do not escalate)

The user chose **"straight to coding"** over the muuli V3→V4→V5 path when asked
(2026-09-18). There is therefore **no `SPEC.md`, no `IMPLEMENTATION_TRACKER.md`
and no `plans/W*-*.md`, by decision — their absence is not an oversight**. The
living draft `.muuli-workflows/2026-09-18-clean-slate-testing/FEATURE.md` is the
spec of record and was updated in this session to match what was built. Do not
create a tracker or wave plans unless the user asks.

The user also chose **two-phase runs** for scenarios 01/02 over the two
alternatives (split assertion set / literal implementation), because
`install.sh`'s `voikko` part installs nothing without an interactive answer,
which would have made §5's engine assertions unreachable in 4 of 10 runs.

## State: nothing is committed

The whole delivery is untracked working tree:

```
 M .gitignore          (pre-existing change, not this task's)
?? .agents/            (pre-existing, not this task's)
?? .muuli-workflows/   (FEATURE.md pre-existing; HANDOFF.md new this session)
?? skills-lock.json    (pre-existing, not this task's)
?? testi/              (ALL of this session's code — 11 files, 1092 lines)
```

`testi/tulokset/` is already covered by `.gitignore:28` (§7.2). The user was
offered a commit and has not asked for one.

## Files written this session

| File | Lines | Responsibility |
|---|---|---|
| `testi/testaa-puhtaalta.sh` | 174 | Entry point: starts docker, builds images, runs the distro × scenario matrix, maps exit codes, chowns logs back to `$SUDO_UID` |
| `testi/Dockerfile.ubuntu` | — | `ubuntu:24.04`; keeps apt lists; `APT::Get::Assume-Yes`; user `testi` with NOPASSWD sudo |
| `testi/Dockerfile.arch` | — | `archlinux:base-devel`; builds `yay-bin` in a stage (§2.3); `/usr/local/bin/yay` wrapper adds `--noconfirm` |
| `testi/tarkista.sh` | 368 | Assertion harness + library. Sourced by every scenario. ALL distro branching lives here (R7) |
| `testi/lo-oikoluku.py` | 223 | UNO probe, 60 s timeout (§7.4), emits JSON |
| `testi/valeprofiilit.sh` | 85 | 2 Firefox + 3 Chromium fixture profiles, deliberately "dirty" |
| `testi/skenaariot/01…05` | 242 | The five scenarios |

## Environment notes (tell EVERY agent)

- **`sudo` on this machine requires a password.** An agent cannot run
  `sudo testi/testaa-puhtaalta.sh` itself. The user runs it; in Claude Code the
  `! <command>` prefix puts the output into the conversation.
- **Docker service is `inactive` and the user is not in the `docker` group**
  (FEATURE §1.4). The entry point starts the service itself and refuses with an
  actionable message when not root.
- **`voikkospell` needs a UTF-8 locale.** In the C locale it stops at the first
  non-ASCII byte with `E: Error while reading from stdin`. Both Dockerfiles set
  `LANG=fi_FI.UTF-8` and generate the locale; `tarkista.sh:vaadi_utf8` exits
  `KOODI_VIRHE` (4) rather than letting it look like a Voikko failure (§7.3).
- **Never probe LibreOffice on the host without `LO_LUOTAIN_PORTTI`.**
  `lo-oikoluku.py` calls `desktop.terminate()`; on the default port 2002 it
  would close the user's running LibreOffice. Use e.g.
  `LO_LUOTAIN_PORTTI=2199` and check `pgrep soffice.bin` first.
- Scenario 04's logic can be exercised on the host with no container at all by
  sourcing `testi/tarkista.sh` under `env -i PATH=/usr/bin:/bin
  LANG=fi_FI.UTF-8 HOME=<sandbox>`. That is how it was verified here.

## Verification done this session

1. `shellcheck -x testi/*.sh testi/skenaariot/*.sh` — clean.
2. `python3 -m py_compile testi/lo-oikoluku.py` — clean.
3. **Scenario 04 end-to-end on the host, sandboxed `$HOME`: 20/20 assertions
   `ok`.** Covers both profile tools, idempotence, backup count, `System
   Profile` untouched, `intl.accept_languages` unchanged.
4. **Assertions 1–5 against the host's real LibreOffice + Voikko: all `ok`.**
   Probe output:
   `{"oikolukijat":["voikko.SpellChecker"],"kielentarkistajat":["voikko.GrammarChecker"],"tavuttajat":["voikko.Hyphenator","org.openoffice.lingu.LibHnjHyphenator"],"oikolukutapa":"XSpellChecker","tarkkailukeha":true,"qwertyxyz":false,"tavutus":"maas=to=pyö=räi=ly"}`
5. **Assertions 7a/7b, 8a/8b, 9a/9b on the host: all `ok`.**
6. **Falsification run (R3-equivalent): every assertion turns red when its
   subject is broken** — Voikko removed from the provider list (1, 2, 4, 5),
   duplicated `dictionary_path` line (13), modified `System Profile` (17, 18),
   corrupted `.bdic` magic (15), deleted nvim `.spl` (9b). No assertion is
   satisfied by construction.

**STALE as of 2026-09-18 15:20** — the above was written before anything ran in
a container. Both images now build and scenario 04 is green on both distros;
see "Matrix status" below for what is verified and what is still unexecuted.

## NEXT ACTION

**The testing work is finished.** Every scenario has run on both distros, every
assertion has been measured at least once in a container, and every red belongs
to a recorded finding. Nothing in `testi/` is known to be broken or unverified.

1. **Commit.** Nothing is committed yet; the user was offered a commit on
   2026-09-18 and has not yet answered. `testi/tulokset/` is already ignored
   (`.gitignore:28`). Note the working tree also carries pre-existing untracked
   items that are NOT this task's (`.agents/`, `skills-lock.json`, the
   `.gitignore` modification) — do not sweep them into the same commit without
   asking.
2. **Then the product decisions**, listed under "Completion condition" below.
   Ask the user which of the four to take, if any — do not start one unasked.

The user runs any test command; an agent cannot (sudo needs a password and a
FIDO touch).

## Matrix status — full run 2026-09-18 16:29 (`tulokset/2026-09-18_162941`)

|        | 01 | 02 | 03 | 04 | 05 |
|--------|----|----|----|----|----|
| ubuntu | EI — reds 21, 7a, 7b | SKIP | EI — reds 1, 3, 4, 5, 7a, 7b | LÄPI 20/20 | LÄPI 4/4 |
| arch   | EI — red 21 | SKIP | LÄPI 14/14 | LÄPI 20/20 | LÄPI 4/4 |

**Ten red assertions in the whole matrix, and every one belongs to a recorded
finding:** 21 twice (finding 1), 7a/7b four times (finding 1b), 1/3/4/5 once
(finding 2). No unexplained red anywhere. The entry point's exit-code mapping,
the `SKIP` path and the two-phase runs all worked.

**Arch 03 is the control for finding 2.** Same scenario, same assertions, the
only variable is the distro: six reds on Ubuntu, zero on Arch. The gap is in
`tools/asenna.sh`'s pacman/yay-only voikko part, not in the scenario.

**Assertion 10b did not run in that matrix** (the run started 16:29:41 and
`tarkista.sh` was edited at 16:32:28, while the last container was still going;
scenarios `source` the harness at startup, so every container read the old
copy). **Resolved:** `--skenaario 05` was rerun at 16:38:39
(`tulokset/2026-09-18_163839`) and 10b is green in a container on both distros,
5/5 each. Scenario 05 is therefore LÄPI 5/5, not 4/4, in the table above.

**Process lesson: do not edit `testi/` while a matrix run is in flight.** The
mount is live, so a mid-run edit produces a log that matches neither version of
the harness.

## Completion condition — not met, and the reason is not the harness

FEATURE's condition is that the entry point exits 0 with every §5 assertion
passing on both distros. It exits non-zero today because of findings 1, 1b and
2, all of which are product gaps the user has decided not to fix yet. The
second half of the condition — a corrupted artifact making scenario 01 exit 1
with `SHA-256 EI TÄSMÄÄ` and nothing written to `$HOME` — **is met**: that is
assertion 20, green in all four 01 runs.

So the remaining work is a product decision, not a testing task:

1. `install.sh:265` / `README.md:167` — the `voikkospell` detector and the
   documented verification command, neither of which works on Debian
   (finding 1b).
2. `tools/asenna.sh:100-123` — the voikko part knows only pacman and yay, and
   exits 0 having installed nothing on Debian (finding 2).
3. `install.sh:239-247` — `kysy()` tests `[ -r /dev/tty ]` instead of whether
   the device can be opened (finding 1).
4. Publishing release `v0.9`, which README already points users at
   (finding 1c).

## Changes made this session

1. **`testi/Dockerfile.arch:28-32` — fixed, the Arch image now builds.**
   `makepkg` produces two packages, `yay-bin-*` and `yay-bin-debug-*`, because
   Arch's stock `/etc/makepkg.conf` has `OPTIONS=(strip ... debug ...)` and
   `yay-bin`'s PKGBUILD has no `options=` line. `cp ./*.pkg.tar.*` therefore
   got two sources and read the target as a directory:
   `cp: target '/home/rakentaja/yay.pkg.tar.zst': No such file or directory`
   (the word `target`, not `cannot create regular file`, is what distinguishes
   this from a glob that matched nothing). Now selects
   `./yay-bin-[0-9]*.pkg.tar.*` and asserts there is exactly one match.
   `makepkg --packagelist` is NOT usable for the selection: it lists the debug
   package too. Verified by running `makepkg` on the host and copying from its
   real output (`pkgname = yay-bin`), plus a falsification run with a planted
   second match (build stops before `cp`, exit 1).

2. **`testi/tarkista.sh:vaite_voikkospell` — diagnostics only.** Reports a
   missing `voikkospell` binary in the `saatu` field instead of a bare `0`. The
   assertion still fails. Verified both ways: with the binary absent from
   `PATH` (a symlink farm of `/usr/bin` minus `voikkospell`) both sub-assertions
   are red with the explanatory text; with it present both are green.

3. **`testi/Dockerfile.arch:57-70` — the Arch image had no `fi_FI.UTF-8`.**
   Scenario 01 stopped at `vaadi_utf8` with
   `# VIRHE: lokaalin merkistö on ANSI_X3.4-1968, ei UTF-8 (LANG=fi_FI.UTF-8)`.
   The `sed` on `/etc/locale.gen` was not the problem: the official
   `archlinux` image carries `NoExtract` rules
   (`archlinux-docker/pacman-conf.d-noextract.conf`) that drop
   `usr/share/i18n/*` and keep back only `en_??`, `i18n*`, `iso*`, `trans*`,
   `C`, `POSIX` and `ANSI_X3.4-1968.gz`. `/usr/share/i18n/locales/fi_FI` is
   therefore absent and `locale-gen` cannot build the locale — and the charmap
   left standing is exactly the one the error reported. The step now deletes
   the locale/i18n `NoExtract` lines (from `/etc/pacman.conf` and any
   `/etc/pacman.conf.d/*.conf`, so it does not depend on which file the image
   uses), reinstalls `glibc` with `--overwrite '*'`, then runs `locale-gen` and
   **gates the build on `locale -a | grep -qix 'fi_FI.utf8'`** — without that
   gate a missing locale only surfaces during a scenario run, far from its
   cause. The man/info/doc restrictions are kept. Verified against the real
   `NoExtract` file (7 locale lines removed, nothing else) and both gate
   directions, and then **confirmed in a real build and run
(`tulokset/2026-09-18_154519`): the gate passed and `arch-01` reached its
assertions.**

**Good news from the same run:** the Arch AUR path works. `yay` installed the
Voikko packages and `voikko.oxt` registered into LibreOffice
(`>>> Adding extension /usr/lib/libreoffice/share/extensions/install/voikko.oxt`),
and phase B exited 0. Only the locale gate stopped the run, so scenario 01's
Arch assertions are still unmeasured.

4. **`testi/skenaariot/02-install-julkaisu.sh` — `SKIP` when the release is
   not published.** Probes `https://github.com/<owner>/<name>/releases/tag/
   <tag>` after the existing github.com reachability check; owner, name and tag
   are all read out of `install.sh`, never copied, so the probe follows the tag
   when it moves. The tag page is used rather than the API because the API rate
   limits unauthenticated calls and a 403 would be indistinguishable from a
   missing release. **Only 404 skips** — 403 and 5xx let the run proceed, so a
   genuine breakage cannot hide behind a skip. Verified both directions against
   real GitHub: the unpublished tag answers 404, `curl/curl`'s published
   release answers 200. `shellcheck -x` clean.

5. **`FEATURE.md` §5.1 — a claim was corrected, no code changed.** Assertion
   2's description said it "identifies which engine is serving" on its own.
   Ubuntu scenario 03 falsified that: with an empty provider list every word is
   valid, so 2 passes with no engine present. The table now says to read 2 and
   3 as a pair, and a note records the measurement.

6. **`testi/tarkista.sh:vaite_enchant` — assertion 10b added.** Ubuntu scenario
   05 passed 4/4, but assertion 10 turned out to be satisfied by construction:
   on the host, with no `~/.config/enchant` directory at all,
   `enchant-lsmod-2 -list-dicts` still prints `fi (voikko)`, because Voikko is
   the only provider for Finnish. Deleting `enchant.ordering` would not turn it
   red — it fails R3. 10b asserts the `fi:voikko` line that `install.sh:375`
   writes, so it measures the part's own trace. Verified in three states:
   correct file green, missing file red, `fi:hunspell` red. **The user was
   asked on 2026-09-18** and chose this over the heavier option (install a
   competing hunspell `fi` dictionary and confirm enchant still picks Voikko),
   which is the only assertion that would test the real defence. Written up in
   FEATURE.md §5.2.

**Watch for this pattern.** Two assertions have now been found green for the
wrong reason (2 in Ubuntu 03, 10 in Ubuntu 05). Both were caught by reading a
green log rather than a red one. The falsification run in "Verification done"
above tested each assertion against a broken subject, but not against an
absent one — an empty provider list, a system where the part never ran. When
adding an assertion, ask what it reports when the thing it names does not
exist at all.

Nothing else in `testi/` was touched. Still nothing is committed.

## Expected red assertions — these are findings, not harness bugs

Do not "fix" these in `testi/`. They are the reason the harness exists, and all
five are already written into FEATURE.md.

1. **Assertion 21 will be red in every scenario 01 and 02 run.**
   `install.sh:kysy()` tests `[ -r /dev/tty ]`, which is `access()` on the
   device node — true whenever `/dev/tty` exists, including with no controlling
   terminal. The message `(ei päätettä — ei kysytä, ohitetaan)` therefore never
   prints; the part is still skipped because the later `read -r vastaus <
   /dev/tty` redirection fails, so the exit code stays 0. The assertion
   compares the composite `viesti=… paluukoodi=…`, so the log shows exactly
   which half failed. **Fix would be a product change** (test openability, e.g.
   `: 2>/dev/null >/dev/tty`, not permissions) — ask the user first.
1b. **Assertions 7a/7b are red in EVERY Debian/Ubuntu run of scenarios
   01/02/03** — new, measured 2026-09-18 in
   `testi/tulokset/2026-09-18_151644/ubuntu-01.log`. `/usr/bin/voikkospell`
   comes from `libvoikko-dev` on Debian; `install.sh` installs
   `voikko-fi libreoffice-voikko libenchant-2-voikko python3-libvoikko` and
   none of them contains the CLI. Arch bundles it into `libvoikko`, so the same
   assertion is green there. Assertions 1–5 are green in the same run — Voikko
   works, only the CLI is missing. **Bigger than the assertion:**
   `install.sh:265` uses `command -v voikkospell` as its "is Voikko already
   installed" test, which on Debian is permanently false, so the installer
   re-suggests the `apt` line after a successful install; `README.md:167`
   documents a verification command that does not exist there. Same pattern in
   `tools/asenna.sh:119`, `tools/vertaa-sanastot.sh:23`. **Product change — the
   user was asked on 2026-09-18 and chose to record it and keep running the
   matrix, not to fix it yet.** Written up in FEATURE.md §5.2.

1c. **Scenario 02 cannot run: release `v0.9` does not exist** — new, measured
   2026-09-18 in `testi/tulokset/2026-09-18_160646/ubuntu-02.log`. The repo has
   no releases (`releases` API returns `[]`) and no remote tags
   (`git ls-remote --tags origin` is empty), while `install.sh:27` sets
   `JULKAISU_TAGI="v0.9"`. The installer 404s on its first download and exits
   1; before the fix that produced 7 reds (25, 21, 7a, 7b, 9b, 14, 15) with one
   shared cause. **User-facing:** README's headline install command
   `curl -fsSL .../raw/v0.9/install.sh | bash` (lines 131, 752, 778) is HTTP
   404 for everyone right now; `raw/main/install.sh` is 302. **The user was
   asked on 2026-09-18 and chose the SKIP path over publishing the release or
   leaving it red.** Scenario 02 now probes the release tag page and skips with
   a message naming the tag and URL (change 4 below). Publishing `v0.9` is
   still an open product decision — nobody has taken it.

2. **Assertions 1, 3, 4, 5 and 7 are red in Ubuntu scenario 03** — predicted,
   now measured (`tulokset/2026-09-18_162407/ubuntu-03.log`, 8 ok / 6 not ok).
   `tools/asenna.sh`'s voikko part only knows `pacman` and `yay`
   (`tools/asenna.sh:100-123`); on Debian/Ubuntu it installs nothing. Two
   details the prediction missed, both worth fixing when the product is
   touched:
   - The script prints **Arch package names to a Debian user**:
     `yay puuttuu — asenna käsin: voikko-fi voikko-libreoffice`. On Debian the
     package is `libreoffice-voikko`, so even a user who follows the advice by
     hand fails.
   - It then finishes `==> Valmis.` and **exits 0** (assertion 26 is green), so
     nothing in the exit status tells the user Voikko was not installed.
   - Assertion 2 is GREEN in this run, which is not a contradiction: see the
     note in FEATURE.md §5.1. An empty provider list makes LibreOffice call
     every word valid. Assertion 3 is what catches it. Do not "fix" assertion 2
     by making it stricter without reading that note.
3. §5.1's expected implementation names in FEATURE.md were wrong and are now
   corrected there: the live names are `voikko.SpellChecker` and
   `voikko.GrammarChecker`, not `org.puimula.ooovoikko.*`. Assertions 1 and 5
   match `voikko` case-insensitively and print the whole provider list.
4. FEATURE.md §2.5 records the PyUNO `isValid` dispatch trap.
5. FEATURE.md §5.5 records the four harness-only assertion numbers (24, 25, 26,
   27) and the `DICPATH` / staged-release deviations.

## Interfaces the next agent will need

Exact, verified — do not re-explore.

- `testi/tarkista.sh` is both a library and a command. Scenarios do
  `source /repo/testi/tarkista.sh`. Exported surface:
  - `vaite <nro> <kuvaus> <odotettu> <saatu>`
  - `vaite_sisaltaa <nro> <kuvaus> <neula> <heinäsuova>`
  - `yhteenveto` — prints the count line, returns 0/1
  - `distro` → `ubuntu` | `arch` | `tuntematon`
  - `vaadi_utf8` — exits 4 unless `locale charmap` is UTF-8
  - `paivita_pakettilistat` — best-effort `apt-get update` / `pacman -Sy`
  - `valmistele_julkaisu <kohdehakemisto>` — stages the five flat release
    asset names from `/repo`
  - `pty_aja <vastaukset> <komento> [args...]` — runs under `script(1)` with a
    pty; needed because `kysy()` reads `/dev/tty`, not stdin
  - `riisu_cr` — strips the CRs `script(1)` leaves
  - `joukko_taysi` (scenarios 01–03), `joukko_profiilit` (04),
    `joukko_sudo_osat` (05)
  - Inputs read from the environment: `XPI_POLKU` (required by `vaite_xpi`),
    `BDIC_NIMI` (default `fi-3-0.bdic`)
  - `KOODI_SKIP=3`, `KOODI_VIRHE=4`
- Scenario exit-code contract, consumed by `testaa-puhtaalta.sh`:
  `0` = LÄPI, `1` = EI (an assertion failed), `3` = SKIP (§3.2), anything else =
  `VIRHE(n)` (§7.3, infrastructure — a dead container or a probe timeout).
- `lo-oikoluku.py` emits one JSON object with keys `oikolukijat`,
  `kielentarkistajat`, `tavuttajat`, `oikolukutapa`, `tarkkailukeha`,
  `qwertyxyz`, `tavutus`. Exit 4 on any failure, never a silent pass.
  Env: `LO_LUOTAIN_PORTTI` (default 2002).
- Image names: `suomen-kieliavut-testi:ubuntu`, `suomen-kieliavut-testi:arch`.
- Container invocation, from `testaa-puhtaalta.sh`:
  `docker run --rm --name kieliavut-testi-<distro>-<nro> -v "$REPO:/repo:ro"
  <kuva> bash /repo/testi/skenaariot/<nn>-*.sh`. No `-t` — scenarios that need
  a pty allocate it themselves.

## Locked invariants that constrain the remaining work

FEATURE.md "Locked invariants" R1–R7, verbatim there. The three that most
constrain edits:

- **R2** — never pre-install Voikko in an image. `paivita_pakettilistat` only
  refreshes the index; that is the line it must not cross.
- **R7** — distro differences live in `tarkista.sh` and the Dockerfiles only.
  A `case "$(distro)"` in a scenario script is drift.
- **R3** — every assertion machine-checkable. The falsification run above is
  the evidence; repeat it for any new assertion.

## Agent-history lesson

Reading `install.sh` and `tools/asenna.sh` in full **before** writing any
scenario is what surfaced the two-phase problem and the Arch-only voikko part
— both of which would otherwise have been discovered as mysterious red
assertions after a 20-minute container run. Brief any subagent with the exact
function it depends on (`kysy()` at `install.sh:239-247`, `put()` at
`install.sh:224-232`), not with the file name.
