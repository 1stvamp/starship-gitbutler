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
  if [ -d "$d" ]; then printf '%s' "$d"; fi
}

# Prints `🌿 <branch>` for a plain git repo (short sha when detached).
render_git() {
  local name
  name="$(git branch --show-current 2>/dev/null)"
  [ -z "$name" ] && name="$(git rev-parse --short HEAD 2>/dev/null)"
  [ -z "$name" ] && return 0
  printf '%s %s' "$GIT_SYMBOL" "$name"
}

# Prints the butler segment for the given gitbutler dir, caching on REFRESH mtime.
cached_butler() {
  local gbdir="$1"
  local refresh="$gbdir/REFRESH"
  local mtime cache_root key cache_file cached_mtime cached_val val

  mtime="$(stat -c %Y "$refresh" 2>/dev/null)"
  cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/starship-gitbutler"
  key="$(printf '%s' "$gbdir" | cksum | cut -d' ' -f1)"
  cache_file="$cache_root/$key"

  if [ -n "$mtime" ] && IFS= read -r cached_mtime < "$cache_file" 2>/dev/null; then
    if [ "$cached_mtime" = "$mtime" ]; then
      cached_val="$(sed '1d' "$cache_file" 2>/dev/null)"
      printf '%s' "$cached_val"
      return 0
    fi
  fi

  val="$(but status --format json 2>/dev/null | render_butler)"
  if [ -n "$mtime" ]; then
    mkdir -p "$cache_root" 2>/dev/null && printf '%s\n%s' "$mtime" "$val" > "$cache_file" 2>/dev/null
  fi
  printf '%s' "$val"
}

main() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local gb
  gb="$(gitbutler_dir)"
  if [ -n "$gb" ]; then
    cached_butler "$gb"
  else
    render_git
  fi
}

# Run main only when executed directly, not when sourced by tests.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main
fi
