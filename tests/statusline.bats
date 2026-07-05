#!/usr/bin/env bats
# Test suite for statusline.sh
# Run with: bats tests/statusline.bats

SCRIPT="$BATS_TEST_DIRNAME/../statusline.sh"

strip_ansi() {
  sed -E 's/\x1b\[[0-9;]*m//g' <<< "$1"
}

@test "0% context does not crash and shows 0%" {
  run bash -c "echo '{\"context_window\":{\"used_percentage\":0}}' | $SCRIPT"
  [ "$status" -eq 0 ]
  clean=$(strip_ansi "$output")
  [[ "$clean" == *"0%"* ]]
}

@test "100% context does not crash (regression: set -e killed script here)" {
  run bash -c "echo '{\"context_window\":{\"used_percentage\":100}}' | $SCRIPT"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  clean=$(strip_ansi "$output")
  [[ "$clean" == *"100%"* ]]
}

@test "completely empty JSON does not crash" {
  run bash -c "echo '{}' | $SCRIPT"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "rate_limits present renders 5h Limit and 7d Limit segments" {
  now=$(date +%s)
  json="{\"context_window\":{\"used_percentage\":28},\"rate_limits\":{\"five_hour\":{\"used_percentage\":62,\"resets_at\":$((now+7200))},\"seven_day\":{\"used_percentage\":17,\"resets_at\":$((now+259200))}}}"
  run bash -c "echo '$json' | $SCRIPT"
  [ "$status" -eq 0 ]
  clean=$(strip_ansi "$output")
  [[ "$clean" == *"5h Limit"* ]]
  [[ "$clean" == *"7d Limit"* ]]
}

@test "context segment says Context, not Ctx" {
  run bash -c "echo '{\"context_window\":{\"used_percentage\":28}}' | $SCRIPT"
  [ "$status" -eq 0 ]
  clean=$(strip_ansi "$output")
  [[ "$clean" == *"Context"* ]]
  [[ "$clean" != *"Ctx "* ]]
}

@test "missing rate_limits falls back to session cost" {
  json='{"context_window":{"used_percentage":45},"cost":{"total_cost_usd":0.42}}'
  run bash -c "echo '$json' | $SCRIPT"
  [ "$status" -eq 0 ]
  clean=$(strip_ansi "$output")
  [[ "$clean" == *'$0.42'* ]]
  [[ "$clean" != *"5h"* ]]
}

@test "past-due reset timestamp does not go negative or crash" {
  now=$(date +%s)
  json="{\"context_window\":{\"used_percentage\":10},\"rate_limits\":{\"five_hour\":{\"used_percentage\":5,\"resets_at\":$((now-100))},\"seven_day\":{\"used_percentage\":5,\"resets_at\":$((now+100))}}}"
  run bash -c "echo '$json' | $SCRIPT"
  [ "$status" -eq 0 ]
  clean=$(strip_ansi "$output")
  [[ "$clean" != *"-"* ]]
}

@test "color thresholds: <50 green code, 50-79 yellow code, >=80 red code" {
  run bash -c "echo '{\"context_window\":{\"used_percentage\":10}}' | $SCRIPT"
  [[ "$output" == *$'\033[32m'* ]]

  run bash -c "echo '{\"context_window\":{\"used_percentage\":60}}' | $SCRIPT"
  [[ "$output" == *$'\033[33m'* ]]

  run bash -c "echo '{\"context_window\":{\"used_percentage\":90}}' | $SCRIPT"
  [[ "$output" == *$'\033[91m'* ]]
}

@test "directory name is extracted from workspace.current_dir" {
  json='{"workspace":{"current_dir":"/home/developer/claudecode/projects/expiry-watcher"},"context_window":{"used_percentage":5}}'
  run bash -c "echo '$json' | $SCRIPT"
  clean=$(strip_ansi "$output")
  [[ "$clean" == *"expiry-watcher"* ]]
}

@test "malformed JSON fails gracefully (nonzero exit, no hang)" {
  run bash -c "echo 'not json' | timeout 5 $SCRIPT"
  [ "$status" -ne 0 ]
}

@test "--no-header suppresses directory and model segments regardless of label text" {
  json='{"workspace":{"current_dir":"/home/developer/some-project"},"model":{"display_name":"Sonnet 5"},"context_window":{"used_percentage":28}}'
  run bash -c "echo '$json' | $SCRIPT --no-header"
  [ "$status" -eq 0 ]
  clean=$(strip_ansi "$output")
  [[ "$clean" != *"some-project"* ]]
  [[ "$clean" != *"Sonnet 5"* ]]
  [[ "$clean" == *"Context"* ]]
}
