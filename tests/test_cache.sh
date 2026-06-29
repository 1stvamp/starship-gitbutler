#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Stub `but` and isolate the cache dir BEFORE sourcing.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export XDG_CACHE_HOME="$tmp/cache"
gbdir="$tmp/gitbutler"; mkdir -p "$gbdir"
: > "$gbdir/REFRESH"

# Stub: `but status --format json` echoes a counter file's stack so we can see recompute.
stubcount="$tmp/count"; echo 0 > "$stubcount"
but() {
  local n; n="$(cat "$stubcount")"; n=$((n+1)); echo "$n" > "$stubcount"
  cat "$DIR/tests/fixtures/one.json"
}
export -f but

# shellcheck source=/dev/null
source "$DIR/gitbutler-branch.sh"

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   - $1"; else echo "FAIL - $1: expected [$2] got [$3]"; fail=1; fi; }

r1="$(cached_butler "$gbdir")"
check "first-value" "🦋 my-feature ↑1" "$r1"
check "first-computed" "1" "$(cat "$stubcount")"

r2="$(cached_butler "$gbdir")"
check "cached-value" "🦋 my-feature ↑1" "$r2"
check "no-recompute" "1" "$(cat "$stubcount")"

# Bump REFRESH -> recompute.
touch -d "+1 second" "$gbdir/REFRESH"
cached_butler "$gbdir" >/dev/null
check "recompute-after-bump" "2" "$(cat "$stubcount")"

exit $fail
