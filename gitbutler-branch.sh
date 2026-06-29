#!/usr/bin/env bash
# starship GitButler-aware branch segment. Always exits 0.

BUTLER_SYMBOL="🦋"
GIT_SYMBOL="🌿"

# Reads `but status --format json` on stdin, prints the butler segment.
render_butler() {
  local out
  out="$(jq -r '
    [ .stacks[].branches[]
      | .name + (if (.commits|length) > 0
                 then " ↑" + (.commits|length|tostring)
                 else "" end)
    ] | join(" | ")
  ' 2>/dev/null)"
  if [ -z "$out" ]; then
    printf '%s workspace' "$BUTLER_SYMBOL"
  else
    printf '%s %s' "$BUTLER_SYMBOL" "$out"
  fi
}
