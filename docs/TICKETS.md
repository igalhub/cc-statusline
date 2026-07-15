# TICKETS — cc-statusline

Full ticket history for this repo, backfilled from git/PR history and
renumbered into strict chronological order (ticket IDs now match the
order work actually shipped in, start to finish). One consequence:
two already-merged commit messages reference the *old* numbers from
before this renumber — `feat: add --no-header flag (CCS-001)` and
`ci: bump actions/checkout to v7 (CCS-002)` — those are what's now
CCS-008 and CCS-009 below. Commit history can't be rewritten after the
fact, so this file is the source of truth for current numbering; those
two commit messages are a known historical mismatch, not an error to
fix. `HANDOFF.md` still has the fuller session-by-session narrative;
this is the ticket-level summary.

---

## CCS-001 — Initial script, tests, and CI

**Status:** DONE

**Description:**
Foundational build: `statusline.sh` (Context %, 5h/7d rate-limit gauges,
session-cost fallback), `tests/statusline.bats`, and
`.github/workflows/ci.yml` (shellcheck + bats). Also fixed, during this
same build, the regression that motivated building real CI in the first
place: `(( expr )) && cmd` as a standalone statement exits nonzero when
`expr` is false, which kills a script under `set -e` — hit at exactly
100% context usage and on empty/fresh-session JSON, both realistic
inputs. Fixed with explicit `if (( expr )); then ... fi` guards,
covered by a named regression test.

**Acceptance criteria:**
- [x] `statusline.sh` renders correctly on real Claude Code stdin JSON
- [x] `set -e` doesn't kill the script on 100% context or empty JSON
- [x] CI runs shellcheck + bats on every push/PR to `master`

---

## CCS-002 — README "Reading the output" section

**Status:** DONE (PR #1)

**Description:**
Added a section explaining each status-line segment (project dir,
model, Context bar with color thresholds, 5h/7d rate-limit segments
with reset countdown, API-key cost fallback), plus practical guidance
on what to do when Context or the 5h window climbs into yellow/red.

**Acceptance criteria:**
- [x] README documents every segment a user will actually see
- [x] Guidance included on when to act (not just what the segments mean)

---

## CCS-003 — Descriptive segment labels

**Status:** DONE (PR #2)

**Description:**
Renamed abbreviated segment labels to full words: `Ctx` → `Context`,
`5h` → `5h Limit`, `7d` → `7d Limit`. Tests were tightened to check the
full new labels rather than incidental substrings, plus a new explicit
test that the context segment says `"Context"` and not `"Ctx "`.

This change is also what exposed the bug fixed by CCS-008: the personal
`~/.claude/statusline-command.sh` combiner script's label-dependent sed
strip broke silently the moment this rename shipped, since it was keyed
to the literal string `"Ctx"`.

**Acceptance criteria:**
- [x] All three segment labels renamed to full words
- [x] Tests check the new full labels, not substrings
- [x] Installed copy on the author's machine re-copied to pick up the
      new labels

---

## CCS-004 — Credit claudino as the inspiration

**Status:** DONE (PR #3)

**Description:**
Added a "Credit" section to README linking to
[niztal/claudino](https://github.com/niztal/claudino) as the origin of
the Claude Code status-line idea, clarifying cc-statusline is a
from-scratch bash+jq rebuild of just the Context/rate-limit gauges
(no game, no token-muncher animation), not a fork.

**Acceptance criteria:**
- [x] Credit section added, positioned right after the intro paragraph
- [x] Clearly distinguishes what cc-statusline does and doesn't include
      relative to claudino

---

## CCS-005 — Genericize real username in example/test-fixture paths

**Status:** DONE (PR #4)

**Description:**
Found during a git identity/content audit: the real Linux username
appeared in README's example command and `tests/statusline.bats`'
fixture data. Genericized to `developer` in current files; shellcheck
and all bats tests re-verified passing after the change.

**Acceptance criteria:**
- [x] No real username in any tracked file
- [x] Tests and lint still pass after genericizing

---

## CCS-006 — Flip repo Private → Public

**Status:** DONE

**Description:**
Repo started private on GitHub; flipped to public after CCS-005 landed
(so no real-username content was ever exposed publicly, even briefly).
Confirmed via `gh repo view`: `"visibility":"PUBLIC"`.

**Acceptance criteria:**
- [x] Content audit (CCS-005) completed before flipping visibility
- [x] Visibility change confirmed via `gh repo view`, not assumed

---

## CCS-007 — Add CLAUDE.md and the docs/PRD.md + docs/SPEC.md + docs/TICKETS.md standard

**Status:** DONE (PR #5, follow-up fix PR #8)

**Description:**
First full doc pass for this repo — had README.md and HANDOFF.md but no
CLAUDE.md and no `docs/` at all. Added `CLAUDE.md` (Claude Code working
instructions), `docs/PRD.md`/`docs/SPEC.md` (why/how), and this file —
initially with only two forward-looking open tickets (now CCS-008 and
CCS-009 below), since nothing else had been ticket-tracked up to that
point. Follow-up (PR #8) fixed CCS-009's acceptance-criteria checkboxes
(left unchecked despite `Status: DONE`) and added the "Ticket status"
summary table that's standard across every other repo in the portfolio.
This ticket itself was later expanded and the whole file renumbered
into strict chronological order (this pass).

**Acceptance criteria:**
- [x] `CLAUDE.md` added
- [x] `docs/PRD.md` and `docs/SPEC.md` added
- [x] `docs/TICKETS.md` added, and later corrected/completed (checkbox
      fix, status table, historical backfill, chronological renumber)

---

## CCS-008 — `--no-header` flag to replace the fragile sed-based header strip

**Status:** DONE

**Description:**
`~/.claude/statusline-command.sh` (a separate, personal script, not
part of this repo) combines its own dirname/model header with
`cc-statusline`'s output by piping through a `sed` pattern keyed to
`cc-statusline`'s current first-segment label string (currently
`"Context"`) to strip the duplicate header before appending. This has
already broken once for real: when the segment label was renamed from
`"Ctx"` to `"Context"` (CCS-003), the old `sed 's/^.*Ctx/Ctx/'` pattern
silently stopped matching and the combined status line started showing
a duplicated dirname/model header until caught and fixed. The same
class of breakage will recur on any future label/format change, with
no error surfaced — just a visibly wrong (but not crashing) status
line.

**Acceptance criteria:**
- [x] Add a `--no-header` (or similarly named) flag to `statusline.sh`
      that suppresses the directory + model segments entirely, so a
      combining script can request "just the gauges" structurally
      instead of stripping them out after the fact with a
      label-dependent regex
- [x] Update `~/.claude/statusline-command.sh` (outside this repo) to
      use the new flag instead of the sed strip
- [x] Add a bats test confirming `--no-header` output has no
      directory/model segment, regardless of what the first gauge
      segment's label currently is

---

## CCS-009 — Bump `actions/checkout` off v4

**Status:** DONE

**Description:**
`.github/workflows/ci.yml` uses `actions/checkout@v4`. `HANDOFF.md`
already notes every CI run so far has carried "GitHub's unrelated Node
20 deprecation notice on `actions/checkout@v4`" as a harmless
annotation — the same warning found and fixed this cycle across
docker-sentinel, devops-study-hub, expiry-watcher, il-job-scraper,
kube-sentinel, and vault-secrets-demo by bumping to the current major
(`v7` as of this writing).

**Acceptance criteria:**
- [x] `actions/checkout@v4` → `v7` (or whatever the current major is at
      the time this is picked up) in `.github/workflows/ci.yml`
- [x] Confirm the Node 20 deprecation annotation no longer appears on
      the next CI run

---

## CCS-010 — Clamp displayed percentage to [0, 100]

**Status:** DONE

**Description:**
`bar()` correctly clamps its rendered width to `[0, width]` when
`used_percentage` is out of range, but the numeric label printed next
to the bar was only truncated to an integer, never range-clamped —
`used_percentage: 134.7` rendered a fully-filled bar next to a `134%`
label; `-5` rendered an empty bar next to a `-5%` label. Hit all three
percentage segments (Context, 5h Limit, 7d Limit), not just Context.

**Acceptance criteria:**
- [x] `ctx_pct`, `five_pct`, `seven_pct` clamped to `[0, 100]` via a new
      `clamp_pct()` helper, applied immediately after integer
      truncation, before `color_for()` or the printed label
- [x] `bar()`'s existing internal width guard left as-is
- [x] 4 new bats tests added (over-100/negative for Context and for
      rate-limit segments); all 11 existing tests pass unmodified
- [x] `docs/SPEC.md` updated to document the clamp

---

## Ticket status

| Ticket | Title | Status |
|---|---|---|
| CCS-001 | Initial script, tests, and CI | DONE |
| CCS-002 | README "Reading the output" section | DONE |
| CCS-003 | Descriptive segment labels | DONE |
| CCS-004 | Credit claudino as the inspiration | DONE |
| CCS-005 | Genericize real username in example/test-fixture paths | DONE |
| CCS-006 | Flip repo Private → Public | DONE |
| CCS-007 | Add CLAUDE.md and the docs/PRD.md + docs/SPEC.md + docs/TICKETS.md standard | DONE |
| CCS-008 | `--no-header` flag to replace the fragile sed-based header strip | DONE |
| CCS-009 | Bump `actions/checkout` off v4 | DONE |
| CCS-010 | Clamp displayed percentage to [0, 100] | DONE |
