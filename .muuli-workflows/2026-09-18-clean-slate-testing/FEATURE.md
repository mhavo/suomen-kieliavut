# Clean-slate installation testing (Ubuntu + Arch)

Status: living draft (V2). Frozen spec becomes `SPEC.md` after the V3 loop.

## Completion condition

`testi/testaa-puhtaalta.sh` runs all five scenarios against both an Ubuntu 24.04
and an Arch container, each from a genuinely clean state, and exits 0 only when
every assertion in §5 passes. Running it with a deliberately corrupted release
artifact makes scenario 01 fail with exit code 1 and the message
`SHA-256 EI TÄSMÄÄ`, with nothing written to the container's home directory.

## Why

The repository ships two installers (`install.sh`, `tools/asenna.sh`) and three
profile-writing tools. CI (`.github/workflows/tarkistus.yml`) checks only static
properties: checksums, dictionary structure, `.bdic` headers, XPI contents. No
job installs anything, so no job can catch a regression in the install path,
in distro detection, or in profile pref writing. Those are the parts users
actually run, and the parts that break when LibreOffice, Firefox, or Chromium
change layout.

## Scope

In scope: both installers, all seven installer parts, both profile tools,
Voikko and hunspell command-line engines, LibreOffice spell/hyphenate/grammar
services, nvim spell file, enchant ordering.

Not in scope:

| Excluded | Why |
|---|---|
| Browser rendering of the red underline | Not observable headlessly; see R6 |
| Installing LibreOffice itself | The repository configures LibreOffice, it does not install it |
| GitHub Actions integration | Local-only by decision §1.4; the harness stays CI-shaped so this can change later |
| KDE/Sonnet, Thunderbird, Emacs/jinx | Documented in `docs/sovellukset.md` but out of this delivery |

## §1 Architecture

**§1.1** New top-level directory `testi/`. `tools/` holds user-facing tools;
test machinery is a different audience and does not belong there.

```
testi/
  testaa-puhtaalta.sh        entry point, orchestrates images and scenarios
  Dockerfile.ubuntu          ubuntu:24.04 base environment
  Dockerfile.arch            archlinux:base base environment
  skenaariot/
    01-install-paikallinen.sh
    02-install-julkaisu.sh
    03-asenna-repo.sh
    04-profiilit.sh
    05-sudo-osat.sh
  tarkista.sh                assertion harness, distro-agnostic
  lo-oikoluku.py             LibreOffice UNO spell/hyphenate/grammar probe
  valeprofiilit.sh           creates empty Firefox and Chromium profiles
```

**§1.2** The repository is bind-mounted read-only at `/repo`. Read-only because
a test must not be able to modify the working tree, and because the 40 MB of
dictionaries must not be copied into an image layer.

**§1.3** Each scenario runs in its own `--rm` container. The clean slate is the
container lifetime, not a cleanup routine — cleanup routines drift from what
they are supposed to remove.

**§1.4** Local execution only. Docker is installed on the maintainer machine but
the service is inactive and the user is not in the `docker` group, so the entry
point is invoked as `sudo testi/testaa-puhtaalta.sh` and starts the service if
needed.

**§1.5** Entry point interface:

```
testi/testaa-puhtaalta.sh                  both distros, all scenarios
testi/testaa-puhtaalta.sh --distro arch    one distro
testi/testaa-puhtaalta.sh --skenaario 04   one scenario, both distros
testi/testaa-puhtaalta.sh --rakenna        force image rebuild
```

## §2 Images

**§2.1** Images contain the slow, stable environment only: LibreOffice,
neovim, hunspell, enchant, curl, sudo, jq, util-linux, and a non-root user
`testi` with passwordless sudo.

No browser is installed. R6 already excludes browser rendering, the profile
tools only read and write files, and `valeprofiilit.sh` fabricates the
profiles — so a browser binary would add an X server, a sandbox and (on
Ubuntu 24.04) a snap wrapper that does not run in a container, for zero
additional assertions.

**§2.2** Voikko packages are deliberately absent from both images. Installing
them is the job of the installer's `voikko` part, and that is the behaviour
under test.

**§2.3** The Arch image builds `yay` in a build stage. `install.sh` proposes
`yay -S --needed voikko-fi voikko-libreoffice` on Arch and `voikko-libreoffice`
exists only in the AUR; without `yay` the test would exercise a command the
user never runs.

**§2.4** Python-UNO bindings differ: Ubuntu ships `python3-uno` into
dist-packages; Arch ships them inside `libreoffice-fresh` and requires
`PYTHONPATH=/usr/lib/libreoffice/program`. `lo-oikoluku.py` resolves both. This
divergence is itself a regression surface the harness will report.

**§2.5** `LinguServiceManager.getSpellChecker()` returns an object implementing
both `XSpellChecker1` and `XSpellChecker`, and PyUNO dispatches `isValid` to the
old one, whose second parameter is a `short` — a `Locale` struct then fails with
`CannotConvertException: Type 17 is not supported!`. `lo-oikoluku.py` therefore
prefers the `com.sun.star.linguistic2.SpellChecker` service, which gives an
unambiguous `XSpellChecker`, and falls back to the LCID form (`1035`).

## §3 Scenarios

Each scenario runs once per distro: 5 × 2 = 10 container runs.

| # | Scenario | Install path | tty | Covers |
|---|---|---|---|---|
| 01 | local release | `install.sh`, `JULKAISU_URL=file:///repo/build` | no | default parts, offline, sudo-part skipping, checksum gate (§6.1) |
| 02 | real release | `install.sh`, GitHub tag `v0.9` | no | published assets match the checksums embedded in `install.sh` |
| 03 | from repository | `tools/asenna.sh` | yes | the second installer's different defaults |
| 04 | profiles | profile tools only | no | multi-profile Firefox and Chromium, idempotence |
| 05 | sudo parts | `install.sh --vain hyphen,oxt,enchant` | yes, `k` fed on stdin | `/usr/share/hyphen/`, `unopkg`, enchant ordering |

**§3.1** Scenarios 01, 02 and 03 are followed by the full §5 assertion set.
Scenarios 04 and 05 assert only their own surface.

**§3.2** Scenario 02 reports `SKIP`, not failure, when its precondition is not
met: the network is unreachable, or the release tag has not been published. A
maintainer working offline must still get a usable result from the other nine
runs.

**The release does not exist today, and that is a product finding** (measured
2026-09-18, `tulokset/2026-09-18_160646/ubuntu-02.log`). The repository has no
releases and no remote tags at all; `install.sh:27` points `JULKAISU_TAGI` at
`v0.9`. `install.sh` therefore takes a 404 on its first download
(`releases/download/v0.9/fi-FI.bdic`) and exits 1, which turned assertions 25,
21, 9b, 14 and 15 red for one shared reason and told us nothing about what the
scenario exists to measure. **The same gap is user-facing:** README's headline
install command, `curl -fsSL .../raw/v0.9/install.sh | bash` (lines 131, 752,
778), returns HTTP 404 for anyone who copies it; `raw/main/install.sh` returns
302. Publishing the release is a product decision and was not taken here.

The precondition probe is the release tag page, not the API (no rate limit),
and only HTTP 404 causes the `SKIP`; 403 and 5xx let the run proceed so a real
breakage cannot hide behind a skip. Owner, name and tag are all read out of
`install.sh` rather than copied, so the probe follows the tag when it moves.
Verified both directions: the unpublished tag answers 404, a published release
(`curl/curl`) answers 200.

**§3.3** Scenarios 01 and 02 run in two phases inside the same container.
Phase A runs without a tty: sudo- and question-requiring parts are skipped and
that skip is asserted (assertion 21). Phase B runs `install.sh --vain voikko`
under a pty with `k` fed, because `kysy()` installs nothing without an answer
and §5's engine assertions need an engine to measure. Scenario 04 needs no
installer. Scenarios 03 and 05 allocate a tty and feed `k`.

The pty comes from `script(1)` inside the container, not from `docker run -t`:
`kysy()` reads `/dev/tty`, not stdin, so a piped answer never reaches it, and
one uniform `docker run` invocation then serves every scenario.

## §4 Assertion harness

**§4.1** `tarkista.sh` emits one line per assertion, TAP-shaped:

```
ok 7 LibreOffice: isValid("tarkkailukehä") = true
not ok 8 LibreOffice: Proofreader fi-FI
    expected: org.puimula.ooovoikko.VoikkoGrammarChecker
    actual:   (empty list)
```

**§4.2** `tarkista.sh` is distro-agnostic. Anything that differs between Ubuntu
and Arch is resolved inside it, never by branching in the scenario scripts.

## §5 Assertions

### §5.1 LibreOffice (`lo-oikoluku.py`, via `soffice --headless --accept=socket,...`)

| # | Assertion | Why this one |
|---|---|---|
| 1 | `LinguServiceManager` offers a Voikko implementation for `fi-FI` | Proves the plugin registered, not merely that a package is on disk. The name is matched case-insensitively on `voikko` and the full provider list is printed: the current `voikko-libreoffice` registers as `voikko.SpellChecker`, not the `.oxt`-era `org.puimula.ooovoikko.VoikkoSpellChecker` (measured LibreOffice 25, 2026-09-18). A literal name would test the history of a name, not the engine |
| 2 | `isValid("tarkkailukehä", fi-FI)` is true | A compound absent from every word list; a hunspell dictionary rejects it, Voikko accepts it. **Read it together with assertion 3, never alone** — see the note below |
| 3 | `isValid("qwertyxyz", fi-FI)` is false | A broken dictionary that accepts everything would otherwise look healthy |
| 4 | `Hyphenator` hyphenates `maastopyöräily` | Separate service from spelling; can be missing while spelling works |
| 5 | `Proofreader` services for `fi-FI` include Voikko (measured name: `voikko.GrammarChecker`) | Grammar checking, the repository's third promise |
| 6 | Scenario 05 only: `unopkg list` contains `fi.hunspell.suomen-kieliavut` | The `.oxt` fallback route |

**Assertion 2 is green when no spellchecker exists at all** (measured
2026-09-18, Ubuntu scenario 03, `tulokset/2026-09-18_162407/ubuntu-03.log`).
With an empty provider list LibreOffice reports every word as valid, so the
probe returns `"oikolukijat": [], "tarkkailukeha": true, "qwertyxyz": true` and
assertion 2 passes while 1, 3, 4 and 5 fail. Assertion 3 is what catches the
empty case, which is exactly why it exists. The earlier falsification run did
not surface this because it removed Voikko from the provider list rather than
emptying the list, so the pair had never been observed in the no-engine state.
Assertion 2's earlier description here claimed it "identifies which engine is
serving" on its own; that was too strong and is corrected above.

### §5.2 Command line

| # | Assertion |
|---|---|
| 7 | `voikkospell` accepts all 13 words of `tools/testisanat.txt` (`C` lines) and rejects an injected misspelling |
| 8 | `hunspell -d fi_FI` loads the dictionary and accepts base forms; compounds are expected to fail and the assertion encodes that difference |
| 9 | `nvim --clean --headless` with `spelllang=fi`: `spellbadword("talo")` empty, a nonsense word flagged |
| 10 | Scenario 05 only: `enchant-lsmod-2 -list-dicts` lists `fi` with the voikko provider |
| 10b | Scenario 05 only: `~/.config/enchant/enchant.ordering` contains the line `fi:voikko` |

**Assertion 10 alone does not measure the enchant part** (measured 2026-09-18,
on the host: no `~/.config/enchant` directory existed at all and
`enchant-lsmod-2 -list-dicts` still printed `fi (voikko)`). Voikko is the only
provider for Finnish, so enchant picks it whether or not the part ever ran —
`install.sh` says as much itself: "tätä ei normaalisti tarvita". Deleting
`enchant.ordering` would not turn assertion 10 red, so it fails R3's
falsification standard and is really a restatement of "Voikko is installed".
Assertion 10b was added for that reason: it checks the line `install.sh:375`
writes, so it fails when the part does not run or writes the wrong provider.
Verified in three states — correct file green, missing file red, `fi:hunspell`
red. The assertion that would test the real defence (install a competing
`fi` hunspell dictionary into `/usr/share/hunspell/` and confirm enchant still
picks Voikko) was considered and not taken: it means deliberately breaking the
system under test, and §5.5's `DICPATH` note explains why that is kept out.

**Assertion 7 is red on Debian/Ubuntu, and that is a product finding** (measured
2026-09-18, `tulokset/2026-09-18_151644/ubuntu-01.log`). `/usr/bin/voikkospell`
ships in `libvoikko-dev` there — a development package `install.sh` does not
install and no end user would. Arch bundles the binaries into `libvoikko`, which
is why the same assertion is green on Arch. Assertions 1–5 stay green in the
same run, so Voikko itself works; only the CLI is absent.

The finding is larger than assertion 7. `install.sh:265` uses
`command -v voikkospell` as its test for "is Voikko already installed", so on
Debian that test is permanently false and the installer re-suggests the `apt`
line even after a successful install. `README.md:167` tells the user to verify
the install with `echo "maastopyöräily" | voikkospell`, a command that does not
exist after following the README's own instructions. The same pattern is in
`tools/asenna.sh:119` and `tools/vertaa-sanastot.sh:23`. Fixing it is a product
change — do not paper over it in `testi/`.

`tarkista.sh:vaite_voikkospell` detects the missing binary and says so in the
`saatu` field instead of reporting `0`; the assertion still fails. Without that
branch the `2>/dev/null` on the `voikkospell` call makes an absent binary look
exactly like a broken Voikko.

### §5.3 Firefox (two fake profiles plus `profiles.ini`, `--kaikki-profiilit`)

| # | Assertion |
|---|---|
| 11 | `~/.local/share/suomen-kieliavut/hunspell/fi_FI.aff` and `.dic` exist and are non-empty |
| 12 | Both profiles set `spellchecker.dictionary_path` to that directory and `spellchecker.dictionary` to `fi-FI` |
| 13 | A second run does not duplicate pref lines |
| 14 | The downloaded `.xpi` is a valid zip and passes `tools/tarkista-manifest.py` |

### §5.4 Chromium (`Default`, `Profile 1`, `System Profile`, `--kaikki-profiilit`)

| # | Assertion |
|---|---|
| 15 | `Dictionaries/fi-3-0.bdic` exists with a `BDic` version 2 header |
| 16 | `Default` and `Profile 1` have `fi` in `spellcheck.dictionaries` |
| 17 | `System Profile` is untouched — the tool documents that it skips it |
| 18 | Each `Preferences` file is still valid JSON and unrelated pre-existing preferences survive |
| 19 | `intl.accept_languages` is unchanged without `--aseta-kieli` |

### §5.5 Numbers the harness adds

Assertion numbers in the log are §5–§6 numbers, not a running count, so a line's
number always means the same assertion. Sub-checks of one assertion carry a
letter (`7a`, `12b`, `23a`). Four numbers exist only in the harness:

| # | Assertion | Scenario |
|---|---|---|
| 24 | `/usr/share/hyphen/hyph_fi_FI.dic` exists and is non-empty | 05 |
| 25 | The published release's assets match the checksums in `install.sh` | 02 |
| 26 | `tools/asenna.sh` exits 0 | 03 |
| 27 | `install.sh --vain hyphen,oxt,enchant` exits 0 | 05 |

Assertion 8 points `hunspell` at the repository with `DICPATH`. Installing a
`fi_FI` hunspell dictionary into `/usr/share/hunspell/` would displace Voikko in
enchant (95,0 % → 88,0 %) — the exact failure `tools/firefox-ota-kayttoon.sh`
exists to avoid.

Scenarios 05 and assertion 20 stage the release into a flat writable directory
rather than using `file:///repo/build`: `hyph_fi_FI.dic` lives in
`dict/hyphen/`, not `build/`, and corrupting a byte needs a writable copy (R1).

## §6 Negative assertions

| # | Assertion | Why |
|---|---|---|
| 20 | One byte corrupted in `build/fi-FI.bdic` under the `file://` release makes `install.sh` exit 1 with `SHA-256 EI TÄSMÄÄ`, and nothing is written to `$HOME` | The checksum gate is the installer's only defence against a tampered release; an untested gate is not a gate |
| 21 | Without a tty, sudo parts are skipped with `(ei päätettä — ei kysytä, ohitetaan)` and the exit code is 0 | Documented `curl \| bash` behaviour |
| 22 | `--vain tuntematon` exits 2 | Argument validation |
| 23 | A second run without `--force` does not overwrite; with `--force` it does | The flag's entire contract |

## §7 Reporting

**§7.1** `testaa-puhtaalta.sh` prints a distro × scenario matrix and exits 0 only
if every assertion passed. `SKIP` (§3.2) does not fail the run.

**§7.2** Full logs go to `testi/tulokset/<timestamp>/<distro>-<scenario>.log`,
ignored by git.

**§7.3** A container that dies mid-run is reported as `VIRHE`, distinct from an
assertion's `not ok`. Conflating an infrastructure failure with a product
failure sends the maintainer to the wrong place.

**§7.4** The UNO connection has a 60-second timeout. `soffice --headless` is
known to hang; a hang is reported as `VIRHE`, never as a silent pass.

## Locked invariants

- **R1** The repository is mounted read-only. A test run can never modify the
  working tree.
- **R2** Voikko packages are never pre-installed in an image. Installing them is
  under test.
- **R3** Every assertion is machine-checkable. No screenshots, no human
  judgement of output.
- **R4** Scenario containers are `--rm` and single-use. Clean state is never
  produced by a cleanup routine.
- **R5** The checksum gate (§6.1, assertion 20) is asserted on every full run,
  not only when checksums change.
- **R6** The harness states in its own `--help` that browser rendering is not
  observed: it verifies that the dictionary is present and the preference is
  set, which is the condition under which browser spell checking works — an
  inference, not an observation.
- **R7** Distro differences are resolved inside `tarkista.sh` and the
  Dockerfiles, never by branching in scenario scripts.

## Edge cases

| Case | Handling |
|---|---|
| Network unreachable | Scenario 02 reports `SKIP`; the run can still pass |
| Release tag not published | Scenario 02 reports `SKIP` and names the tag and URL (§3.2) |
| Docker service inactive | Entry point starts it, or fails with an actionable message |
| Image missing | Built automatically before the scenario runs |
| `soffice` hangs | 60 s timeout, reported `VIRHE` (§7.4) |
| AUR build of `voikko-libreoffice` fails | Reported `VIRHE` for the Arch run; Ubuntu results still reported |
| GitHub release tag moves past `v0.9` | Scenario 02 reads the tag from `install.sh`'s `JULKAISU_TAGI`, never a hardcoded copy |
| `unopkg` lock file left behind | Scenario 05 containers are single-use (R4), so a stale lock cannot leak into another run |
| Two profiles already configured | Assertion 13 covers re-running; the profile tools must be idempotent |

## §9 Product fixes taken 2026-09-18 (findings 1, 1b, 2)

The user chose to fix three of the four recorded findings. Finding 1c
(publishing release `v0.9`) was **not** taken and remains open; scenario 02
therefore still reports `SKIP`.

**Finding 1 — `install.sh:kysy()` tested permissions, not openability.**
`[ ! -r /dev/tty ]` is `access()` on the device node and is true whenever the
node exists, including in a process with no controlling terminal. The test is
now `! { true <>/dev/tty; } 2>/dev/null`, which opens the device for reading and
writing — exactly the two uses that follow. Verified both directions on the
host: under `setsid` the old test said "terminal" and the new one says "no
terminal"; under `script(1)` both say "terminal". **Assertion 21 should now be
green in every scenario 01 and 02 run** — that is the measurement that confirms
the fix, and it has not yet been made in a container.

**Finding 1b — "is Voikko already installed" must not be `command -v
voikkospell`.** On Debian that binary ships in `libvoikko-dev`, which
`install.sh` does not install and Voikko does not need. `install.sh` now asks
the package manager (`pacman -Q` on Arch, `dpkg-query -W -f='${Status}'` on
Debian, `command -v voikkospell` only on an unknown distro), and the CLI test is
a separate optional step that names `libvoikko-dev` when the binary is absent
instead of looking like a failure. `README.md`'s "Tarkista että se toimii"
section carries the same note. Verified with a `dpkg-query` stub across seven
package states, including one package present and the other missing.

**Consequence for assertion 7 — an open decision.** The product now states that
`voikkospell` is optional on Debian, so assertions 7a/7b are red there for a
behaviour the product no longer promises. Until 7 is made distro-aware in
`tarkista.sh` (R7 puts that branching there, and `vaite_voikkospell` already has
the branch that detects the absent binary), the completion condition cannot be
met on Ubuntu. Nobody has taken this decision.

**Finding 2 — `tools/asenna.sh` knew only pacman and yay.** It now detects the
distro from `/etc/os-release` (`ID` plus `ID_LIKE`, so derivatives land in the
right branch), carries a per-distro package list and installer, and asks the
right package manager whether each package is present. Three behaviours changed:
Debian installs the four `apt` packages instead of printing Arch package names;
an unknown distro says so instead of naming Arch packages; and the script
**exits 1** when anything was left uninstalled, where it previously printed
`==> Valmis.` and exited 0. Verified on the host with a stubbed `/etc/os-release`
across four distro values — `debian`, `ubuntu`+`ID_LIKE=debian`,
`manjaro`+`ID_LIKE=arch`, `void` — each landing in the intended branch with the
intended exit code, and the real Arch path unchanged and green.

**Assertion 26 still expects exit 0** and should stay green: on Ubuntu the
packages now install, so nothing is left over. If it turns red, the Debian
install itself failed — that is the assertion doing its job, not drift.

**Not yet measured in a container.** Every verification above is host-side. The
matrix has not been rerun since the fixes; `sudo testi/testaa-puhtaalta.sh` is
the next measurement.

### Finding 3 — a `curl | bash` user cannot finish the Chromium part

Found 2026-09-18 while writing `ASENNUS.md`, not by the harness. `install.sh`
drops the `.bdic` and then tells the user to run
`tools/chromium-ota-kayttoon.sh` — a file that exists only in a repository
clone. A user who installed with the one-line `curl | bash` has no clone, so
the instruction names something they do not have.

Cloning is not the only gap: `chromium-ota-kayttoon.sh` computes
`REPO="$(dirname "$BASH_SOURCE")/.."` and calls
`python3 "$REPO/tools/pref-kirjoitus.py"`, so downloading the one script does
not work either. Both files must land in a `tools/` directory together.
`ASENNUS.md` therefore instructs the user to create `~/suomen-kieliavut/tools`
and fetch both — five commands where the rest of the guide needs one.

Chromium is the only part with this shape. Firefox is unaffected: its manual
step is an `.xpi` the installer has already cached, installed through the
browser's own UI.

Not fixed. The options, none taken: teach the five-command block (what
`ASENNUS.md` does today), make `install.sh` write the Chromium preference
itself, or ship a standalone single-file version of the tool as a release
asset. Assertion 16 does not catch this — scenario 04 runs the tool from the
mounted repo, which is exactly the situation the affected user is not in.

**Finding 3 resolved 2026-09-18 — the installer fetches the tools it needs.**
The rejected option was embedding the JSON logic in `install.sh`:
`tools/pref-kirjoitus.py`'s own docstring records that this logic already lived
in two scripts as heredocs and had to be fixed twice, and the write is an
atomic `os.replace()` because a truncated `Preferences` makes Chromium reset
the whole profile. That is not logic to keep in two copies.

Instead both tool files are release assets, and `install.sh` downloads them
into `$TYOHAK/tools/` under the same `nouda_ja_varmenna` SHA-256 gate as the
dictionaries, then runs the tool. The tools themselves are unchanged:
`chromium-ota-kayttoon.sh` derives its root from `$BASH_SOURCE/..` and finds
`tools/pref-kirjoitus.py` at that layout with no modification.

The part refuses to write while a browser is running (`pgrep -x`
'chromium|chromium-browser|chrome|google-chrome'), because Chromium rewrites
`Preferences` on exit and would silently discard the change — to the user that
looks like an installation that did nothing. It also refuses without `python3`
or without `pgrep`, on the principle that an unknown browser state is treated
as the bad one. Every refusal is a `JAI` entry naming the exact command to run
later, never an error: the dictionary is already in place.

`--kaikki-profiilit` was added to `install.sh` and passed through, because
`ASENNUS.md` needed to offer it and the flag did not exist.

Verified on the host against a `file://` release with a sandboxed `$HOME`:
both tools fetched and checksum-verified; `spellcheck.dictionaries` written as
`["fi"]`; a pre-existing unrelated preference preserved; `intl.accept_languages`
unchanged; a backup made. Re-run made no second backup (idempotent). A tampered
`chromium-ota-kayttoon.sh` in the release was rejected with `SHA-256 EI TÄSMÄÄ`
and nothing written. The running-browser branch fired for real on this machine,
which has Chromium open. With `--kaikki-profiilit` and three profiles, `Default`
and `Profile 1` were written and `System Profile` left untouched.

Companion changes: two `SUMMA_` lines in `install.sh`, two lines in
`SHA256SUMS`, both files added to `julkaisu.yml`'s checksum list and `files:`
list, and `tarkistus.yml`'s hard-coded expected count raised from 5 to 7.
`tarkista.sh:valmistele_julkaisu` now stages the two tools as well — without
that, scenario 01 would fail at download and blame the release rather than the
staging function.
