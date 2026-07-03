#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Stub `but` and isolate the cache dir BEFORE sourcing.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export XDG_CACHE_HOME="$tmp/cache"
gbdir="$tmp/gitbutler"; mkdir -p "$gbdir"
: > "$gbdir/REFRESH"

stubcount="$tmp/count"; echo 0 > "$stubcount"

# shellcheck source=/dev/null
source "$DIR/gitbutler-branch.sh"

# Override the status fetcher (above the `timeout but` wrapper) with a counter
# stub so we can observe when a recompute actually happens. Invoked indirectly
# by the sourced cached_butler, so shellcheck can't see the call site.
# shellcheck disable=SC2329,SC2317
but_status_json() {
  local n; n="$(cat "$stubcount")"; n=$((n+1)); echo "$n" > "$stubcount"
  cat "$DIR/tests/fixtures/one.json"
}

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   - $1"; else echo "FAIL - $1: expected [$2] got [$3]"; fail=1; fi; }

r1="$(cached_butler "$gbdir")"
check "first-value" "⧓ my-feature ↑1" "$r1"
check "first-computed" "1" "$(cat "$stubcount")"

r2="$(cached_butler "$gbdir")"
check "cached-value" "⧓ my-feature ↑1" "$r2"
check "no-recompute" "1" "$(cat "$stubcount")"

# Bump REFRESH mtime -> recompute. `sleep 1` ensures whole-second mtime advances
# (portable across GNU/BSD; avoids GNU-only `touch -d "+N second"`).
sleep 1; touch "$gbdir/REFRESH"
cached_butler "$gbdir" >/dev/null
check "recompute-after-bump" "2" "$(cat "$stubcount")"

# Cache failure -> degraded to direct compute. The unreadable cache dir forces a
# recompute regardless of mtime.
chmod 000 "$XDG_CACHE_HOME"
rD="$(cached_butler "$gbdir")"
check "degraded-value" "⧓ my-feature ↑1" "$rD"
check "degraded-direct-compute" "3" "$(cat "$stubcount")"
chmod 755 "$XDG_CACHE_HOME"

exit $fail
