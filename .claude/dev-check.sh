#!/usr/bin/env bash
# Project-specific service health checks.
# Each check prints: SERVICE_NAME | STATUS | detail
# STATUS: UP or DOWN

set -uo pipefail

if command -v jq >/dev/null 2>&1; then
  echo "jq | UP | $(jq --version)"
else
  echo "jq | DOWN | jq not found on PATH"
fi

if command -v bats >/dev/null 2>&1; then
  echo "bats | UP | $(bats --version)"
else
  echo "bats | DOWN | bats not found on PATH"
fi

if command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck | UP | $(shellcheck --version | head -2 | tail -1)"
else
  echo "shellcheck | DOWN | shellcheck not found on PATH"
fi
