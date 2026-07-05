# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A ~120-line bash + `jq` status line script for Claude Code — reads the
status JSON Claude Code pipes to it on stdin and prints one line: project
directory, model, a context-usage bar, and 5-hour/7-day rate-limit bars
(or a session-cost fallback on API-key billing). See `docs/PRD.md` for
why this exists and `docs/SPEC.md` for exactly how it works.

## Commands

```bash
# Lint
shellcheck statusline.sh

# Test (bats)
bats tests/statusline.bats

# Manual smoke test (no Claude Code needed)
echo '{"model":{"display_name":"Sonnet 5"},"workspace":{"current_dir":"/home/developer/some-project"},"context_window":{"used_percentage":28},"rate_limits":{"five_hour":{"used_percentage":62,"resets_at":'$(($(date +%s)+7931))'},"seven_day":{"used_percentage":17,"resets_at":'$(($(date +%s)+259200))'}}}' | ./statusline.sh
```

## Architecture

Single script, no dependencies beyond `jq`. No build step, no package
manager — `cp statusline.sh ~/.claude/scripts/statusline.sh` is the
entire "install." See `docs/SPEC.md` for the exact parsing/rendering
logic and the edge cases the test suite covers.

## Test Isolation

N/A — this is a pure bash script with no external services, no mocks,
no network calls to isolate. Tests run the real script against
hand-constructed JSON fixtures via bats.

## Commit Convention

Format: `type: short description` (no ticket IDs — this is a solo,
untracked-by-ticket-system side project; see `docs/TICKETS.md` for the
lightweight backlog it does use).

Types: `feat`, `fix`, `test`, `docs`, `chore`, `ci`

## Branch Naming

Pattern: `type/short-description`. Default branch: `master`.

## CI & Merge Discipline

Branch + PR + CI green before merge — CI runs `shellcheck` and the bats
suite on every push/PR to `master`. No exceptions (this is a real,
publicly-visible project, unlike the personal `claude-config`/
`project-template` tooling repos which have a stated direct-to-master
exception).

## Session Handoff

At the end of every session, write a `HANDOFF.md` in the repo root
(gitignored) with exactly four fields: **Current ticket**, **Last
action**, **Next step**, **Blockers**. Read it at the start of every
session before doing anything else.
