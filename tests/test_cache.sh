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

# A repo the app hasn't stamped with a REFRESH file: the cache must still work,
# bounded by a TTL, rather than shelling out on every render.
gbdir2="$tmp/gitbutler-noref"; mkdir -p "$gbdir2"
echo 0 > "$stubcount"

rN1="$(cached_butler "$gbdir2")"
check "no-refresh-value" "⧓ my-feature ↑1" "$rN1"
check "no-refresh-computed" "1" "$(cat "$stubcount")"

rN2="$(cached_butler "$gbdir2")"
check "no-refresh-cached-value" "⧓ my-feature ↑1" "$rN2"
check "no-refresh-no-recompute" "1" "$(cat "$stubcount")"

# A zero TTL expires the entry immediately, so the fallback still recomputes.
BUT_CACHE_TTL=0 cached_butler "$gbdir2" >/dev/null
check "no-refresh-ttl-expiry" "2" "$(cat "$stubcount")"

# REFRESH appearing later invalidates the TTL-stamped entry, then keys the
# cache as usual. `sleep 1` keeps the new mtime clear of the stamp's second.
sleep 1; : > "$gbdir2/REFRESH"
cached_butler "$gbdir2" >/dev/null
check "refresh-appearing-invalidates" "3" "$(cat "$stubcount")"
cached_butler "$gbdir2" >/dev/null
check "refresh-then-cached" "3" "$(cat "$stubcount")"

# A failing `but` renders the error marker and is deliberately not cached, so
# the segment recovers as soon as `but` works again rather than serving a stale
# error until REFRESH moves.
gbdir3="$tmp/gitbutler-failing"; mkdir -p "$gbdir3"
: > "$gbdir3/REFRESH"
echo 0 > "$stubcount"
# shellcheck disable=SC2329,SC2317
but_status_json() {
  local n; n="$(cat "$stubcount")"; n=$((n+1)); echo "$n" > "$stubcount"
  return 2
}

rE1="$(cached_butler "$gbdir3")"
check "error-value" "⧓ ?" "$rE1"
check "error-computed" "1" "$(cat "$stubcount")"
cached_butler "$gbdir3" >/dev/null
check "error-not-cached" "2" "$(cat "$stubcount")"

# `but` starts working again: no stale error to clear out first.
# shellcheck disable=SC2329,SC2317
but_status_json() {
  local n; n="$(cat "$stubcount")"; n=$((n+1)); echo "$n" > "$stubcount"
  cat "$DIR/tests/fixtures/one.json"
}
check "recovers-after-error" "⧓ my-feature ↑1" "$(cached_butler "$gbdir3")"

exit $fail
