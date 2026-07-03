# cc-statusline

Claude Code status line — Context % + Rate Limit gauges

Minimal, dependency-light (`jq` only) status line for Claude Code. Shows
project dir, model, Context usage bar, and 5-hour / 7-day rate limit bars
with reset countdowns — color-coded green → yellow → red. Falls back to
session cost automatically if you're on API-key billing instead of a
Pro/Max OAuth login (rate_limits won't be present in that case).

No game, no marketing nudges, no upstream dependency — plain bash + jq,
~110 lines, easy to read and modify.

## Credit

The idea for a Claude Code status line came from [claudino](https://github.com/niztal/claudino)
by [@niztal](https://github.com/niztal) — a status-line "pet" that munches
your tokens while Claude thinks, plus a full interactive terminal game.
cc-statusline is a from-scratch rebuild of just the parts that were
genuinely useful to my own workflow (the Context/rate-limit gauges), in
plain bash + jq instead of Node, with no game and no upstream dependency.
Worth checking out claudino if the game and the token-muncher animation
sound fun — that's not what this repo does.

## Install

1. Make sure `jq` is installed:
   ```
   sudo apt install jq
   ```

2. Copy the script into place:
   ```
   mkdir -p ~/.claude/scripts
   cp statusline.sh ~/.claude/scripts/statusline.sh
   chmod +x ~/.claude/scripts/statusline.sh
   ```

3. Add this to `~/.claude/settings.json` (merge into the existing JSON,
   don't overwrite the whole file):
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/scripts/statusline.sh"
     }
   }
   ```

4. Restart Claude Code (or start a new session). You should see the
   status line at the bottom of the terminal — this also works fine
   inside PyCharm's built-in terminal panel, since it's just reading
   stdin/writing stdout like any other shell command.

## Test without Claude Code

```bash
echo '{"model":{"display_name":"Sonnet 5"},"workspace":{"current_dir":"/home/igalv/some-project"},"context_window":{"used_percentage":28},"rate_limits":{"five_hour":{"used_percentage":62,"resets_at":'$(($(date +%s)+7931))'},"seven_day":{"used_percentage":17,"resets_at":'$(($(date +%s)+259200))'}}}' | ~/.claude/scripts/statusline.sh
```

Expected output (colors won't show in plain text):
```
some-project │ Sonnet 5 │ Context ▓▓░░░░░░ 28% │ 5h Limit 62% (2h12m) │ 7d Limit 17% (72h0m)
```

## Reading the output

Left to right:

| Segment | Meaning |
|---|---|
| `some-project` | Current project directory name (basename of `cwd`) |
| `Sonnet 5` | Model active in this session |
| `Context ▓▓░░░░░░ 28%` | Context window usage. The bar has 8 segments; filled = used. Color-coded green (<50%) → yellow (50–79%) → red (≥80%) |
| `5h Limit 62% (2h12m)` | % used of the rolling 5-hour rate-limit window, and time until it resets |
| `7d Limit 17% (72h0m)` | % used of the rolling 7-day rate-limit window, and time until it resets |

If you're on API-key billing instead of Pro/Max OAuth, the two rate-limit
segments are replaced by a single `$X.XX session` cost segment instead.

**What to actually do with this:** context and the 5-hour window are the
two to watch during a long session. If `Context` climbs into yellow/red,
consider `/compact` or starting a fresh session rather than letting
Claude Code auto-compact for you (auto-compact can drop earlier context
you still needed). If `5h Limit` climbs into red with a short reset time,
that's the moment to slow down, switch to a lighter model for
non-critical work, or plan around the reset rather than getting blocked
mid-task. The 7-day window is usually the least urgent of the three —
mostly worth a glance rather than active management.

## Notes

- `rate_limits` only appears for Pro/Max subscribers logged in via OAuth,
  and only after the first API response in a session. You're on Pro, so
  this will populate — just not on a brand-new session before the first
  message completes.
- If you're ever on API-key billing instead, the script auto-detects the
  missing field and shows `$X.XX session` cost instead.
- Color thresholds: green < 50%, yellow 50–79%, red ≥ 80%. Edit `color_for()`
  in the script if you want different cutoffs.
- Bar width is 8 characters; change the `8` in the `bar "$ctx_pct" 8` call
  if you want it wider/narrower.
- Tested edge cases: 0%, 100%, empty JSON (fresh session), past-due reset
  timestamps, missing `rate_limits` key entirely.

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json`, or run
`/statusline delete` inside Claude Code.
