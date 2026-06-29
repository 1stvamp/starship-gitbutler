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

# Prints the gitbutler data dir for the current repo if present, else nothing.
gitbutler_dir() {
  local d
  d="$(git rev-parse --git-path gitbutler 2>/dev/null)" || return 0
  [ -d "$d" ] && printf '%s' "$d"
}

# Prints `🌿 <branch>` for a plain git repo (short sha when detached).
render_git() {
  local name
  name="$(git branch --show-current 2>/dev/null)"
  [ -z "$name" ] && name="$(git rev-parse --short HEAD 2>/dev/null)"
  [ -z "$name" ] && return 0
  printf '%s %s' "$GIT_SYMBOL" "$name"
}

main() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  if [ -n "$(gitbutler_dir)" ]; then
    but status --format json 2>/dev/null | render_butler
  else
    render_git
  fi
}

# Run main only when executed directly, not when sourced by tests.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main
fi
