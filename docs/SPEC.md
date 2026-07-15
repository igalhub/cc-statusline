# SPEC — cc-statusline

Technical spec of `statusline.sh`'s exact behavior. `docs/PRD.md` covers
why; this covers how.

---

## Contract

Claude Code pipes a JSON status object to the script's stdin on every
render; the script prints exactly one line to stdout. `set -euo
pipefail` is on throughout — any unhandled error must be caught
explicitly (see the `bar()` zero-case note below) rather than left to
propagate, since a crash here means no status line at all, not a
degraded one.

## Input fields read (all via `jq`, all with `//` fallback defaults)

| Field | Fallback | Used for |
|---|---|---|
| `.model.display_name` | `"Claude"` | Model segment |
| `.workspace.current_dir` (falls back to `.cwd`) | `""` | Directory segment (via `basename`) |
| `.context_window.used_percentage` | `0` | Context bar |
| `.rate_limits` (existence check only) | — | Whether to render rate-limit segments or the cost fallback |
| `.rate_limits.five_hour.used_percentage` / `.resets_at` | `0` / absent | 5h Limit segment |
| `.rate_limits.seven_day.used_percentage` / `.resets_at` | `0` / absent | 7d Limit segment |
| `.cost.total_cost_usd` | absent → segment omitted | Session-cost fallback |

Every percentage is truncated to an integer with bash's `${var%.*}`
(string suffix strip on the fractional part), not rounded — `28.7%`
displays as `28%`. It is then clamped to `[0, 100]` via `clamp_pct()`
(same reasoning as `bar()`'s width clamp below: upstream can send a
`used_percentage` slightly over 100 or negative, and the displayed
label shouldn't visually contradict the bar it sits next to) — `134.7%`
displays as `100%`, `-5%` displays as `0%`. This clamp applies to all
three percentages (Context, 5h Limit, 7d Limit).

## Rendering

**`color_for(pct)`** — `>= 80` red, `>= 50` yellow, else green. Bright
red (`\033[91m`), not dark red, because dark red is unreadable on dark
terminal themes — a real fix, not an aesthetic choice.

**`bar(pct, width=10)`** (called with `width=8` for the context bar) —
`filled = pct * width / 100`, clamped to `width` if it overflows (a
`used_percentage` slightly over 100 from upstream shouldn't overflow
the bar). Renders `▓` for filled cells, `░` for empty. The zero-case
guard (`if (( filled > 0 ))`) exists because bash's `printf` with a
`seq` argument list still runs once even when `seq 1 0` produces no
output — without the guard, `printf '%0.s▓' $(seq 1 0)` would print one
unwanted `▓` instead of zero.

**`fmt_reset(resets_at)`** — `resets_at - now`, floored at `0` (a
past-due reset timestamp — e.g. clock skew, or the script running just
after the actual reset — renders as `0m`, never a negative duration).
Formats as `HhMm` if `h > 0`, else just `Mm`.

## CLI flags

**`--no-header`** — suppresses the directory + model segments entirely;
only the gauge segments (Context, 5h/7d Limit or session cost) render.
Parsed from `"$@"` before stdin is read. Intended for a combining
script that already renders its own dirname/model header and only
wants cc-statusline's gauges appended — see `~/.claude/statusline-command.sh`
(a separate, personal script, not part of this repo) for the actual
usage. Added to replace a fragile `sed`-based header strip that was
keyed to the literal current segment label string and had already
broken once for real on a label rename (see `docs/TICKETS.md` CCS-008).

## Segment assembly

Segments are built into a bash array in a fixed order — directory,
model, context bar, then either (5h Limit, 7d Limit) or (session cost) —
and joined with `" │ "`. The directory segment is omitted entirely if
`dirname` resolves empty (e.g. `current_dir` absent from the input).
Both the directory and model segments are skipped entirely under
`--no-header`, regardless of `dirname`.

**Branch point:** `has_rate_limits` is computed once
(`if .rate_limits then "yes" else "no" end`) and gates which of the two
mutually exclusive segment groups renders. This is the API-key-billing
vs. Pro/Max-OAuth distinction — `rate_limits` is only present for
OAuth-authenticated Pro/Max sessions, and only after the first API
response completes (a brand-new session before that point looks like
the API-key-billing case even on Pro/Max, until the first response
lands).

## Color thresholds and bar width — where to change them

`color_for()`'s `80`/`50` cutoffs and `bar "$ctx_pct" 8`'s `8`-character
width are the two things most likely to want tuning per-user taste —
both are called out explicitly in the README as the places to edit.

## Test coverage (`tests/statusline.bats`)

15 tests, each constructing a JSON fixture and asserting on the
script's actual stdout — not testing internal functions in isolation,
since the whole script is small enough that end-to-end is the natural
unit:

- 0% and 100% context (the 100% case is a named regression test: `set
  -e` previously killed the script on this exact input)
- Completely empty JSON input (fresh-session shape)
- `rate_limits` present → both limit segments render
- Segment label is exactly `"Context"`, not an abbreviation
- `rate_limits` absent → session-cost fallback renders instead
- A past-due `resets_at` doesn't go negative or crash
- All three color thresholds (green/yellow/red) produce the right ANSI
  code
- Directory name correctly extracted from `workspace.current_dir`
- Malformed JSON input fails gracefully — nonzero exit, no hang (not a
  silently-wrong render)
- `--no-header` suppresses directory and model segments regardless of
  the current label text, while still rendering the Context segment
- Over-100 and negative `used_percentage` clamp the displayed label to
  `100%`/`0%` respectively, for both Context and the rate-limit
  segments

## CI

`.github/workflows/ci.yml` — checkout, install `shellcheck` + `bats` +
`jq`, `shellcheck statusline.sh`, `bats tests/statusline.bats`. Runs on
push/PR to `master`.
