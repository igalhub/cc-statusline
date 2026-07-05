# TICKETS — cc-statusline

Real, currently-open gaps — not a backfilled history of already-shipped
work (see `HANDOFF.md` for the detailed session-by-session record of
what's already landed: label renaming, README sections, the git
identity/content audit, the private→public flip).

---

## CCS-001 — `--no-header` flag to replace the fragile sed-based header strip

**Status:** DONE

**Description:**
`~/.claude/statusline-command.sh` (a separate, personal script, not
part of this repo) combines its own dirname/model header with
`cc-statusline`'s output by piping through a `sed` pattern keyed to
`cc-statusline`'s current first-segment label string (currently
`"Context"`) to strip the duplicate header before appending. This has
already broken once for real: when the segment label was renamed from
`"Ctx"` to `"Context"` (see `HANDOFF.md`), the old `sed 's/^.*Ctx/Ctx/'`
pattern silently stopped matching and the combined status line started
showing a duplicated dirname/model header until caught and fixed. The
same class of breakage will recur on any future label/format change,
with no error surfaced — just a visibly wrong (but not crashing)
status line.

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

## CCS-002 — Bump `actions/checkout` off v4

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
- [ ] `actions/checkout@v4` → `v7` (or whatever the current major is at
      the time this is picked up) in `.github/workflows/ci.yml`
- [ ] Confirm the Node 20 deprecation annotation no longer appears on
      the next CI run
