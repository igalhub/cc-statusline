# PRD — cc-statusline

## Problem statement

Claude Code's default status line doesn't surface the two numbers that
matter most during a long session: how full the context window is, and
how close the rolling rate-limit windows are to running out. Without
that visibility, a session either gets silently auto-compacted
(dropping context you may still have needed) or gets blocked mid-task
by a rate limit with no warning it was coming.

## Goals

- Show, at a glance, in the terminal status line: current project
  directory, active model, context-window usage (bar + %), and both
  the 5-hour and 7-day rate-limit windows (% used + time to reset)
- Fall back gracefully to a session-cost display when rate limit data
  isn't available (API-key billing instead of Pro/Max OAuth)
- Stay dependency-light — `jq` only, no Node/Python runtime, no
  package manager, no build step
- Be trivially readable and editable — a single ~135-line script, not
  a framework

## Non-goals

- **Not a game or gamified UI** — this is a deliberate scope cut from
  the project that inspired it ([claudino](https://github.com/niztal/claudino)),
  which includes a token-muncher animation and interactive terminal
  game. cc-statusline is only the gauges.
- **Not a general-purpose statusline framework** — no plugin system,
  no theming beyond the three hardcoded color thresholds
- **Not packaged/distributed** — install is `cp` the script into
  place; no npm/pip/homebrew packaging

## Users

Personal tool, one user (the author), used across every Claude Code
session on this machine. Shared publicly (public GitHub repo) since the
gauges are broadly useful to any Claude Code user on Pro/Max billing,
but not maintained as a product with external users in mind.

## Success criteria

- The status line renders correctly (no crash, no hang) on every input
  shape Claude Code can actually send: fresh session (no rate_limits
  yet), API-key billing (no rate_limits ever), 0%/100% usage, and a
  past-due reset timestamp
- Context and 5-hour-window color thresholds give enough warning to act
  (switch models, `/compact` deliberately, or pause) before either one
  actually blocks work
- Stays a single script simple enough to read and modify in one sitting
