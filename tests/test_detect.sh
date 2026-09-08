#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export XDG_CACHE_HOME="$tmp/cache"
GIT_TEMPLATE_DIR="$(mktemp -d)"; export GIT_TEMPLATE_DIR

stubcount="$tmp/count"; echo 0 > "$stubcount"

# shellcheck source=/dev/null
source "$DIR/gitbutler-branch.sh"

# Count `but` invocations so a stale repo can be shown not to shell out at all.
# Invoked indirectly by the sourced cached_butler, so shellcheck can't see the
# call site.
# shellcheck disable=SC2329,SC2317
but_status_json() {
  local n; n="$(cat "$stubcount")"; n=$((n+1)); echo "$n" > "$stubcount"
  cat "$DIR/tests/fixtures/one.json"
}

# main() would otherwise query the terminal and wrap the output in escapes.
# shellcheck disable=SC2329,SC2317
setup_colors() { :; }

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   - $1"; else echo "FAIL - $1: expected [$2] got [$3]"; fail=1; fi; }

# Builds a repo at $1 on branch $2, with a .git/gitbutler dir when $3 is "gb".
mkrepo() {
  mkdir -p "$1"; ( cd "$1" || exit 1
    git init -q -b "$2" .
    git config user.email t@t.t; git config user.name t
    echo x > x; git add x; git commit -q -m init
    [ "${3:-}" = "gb" ] && mkdir -p .git/gitbutler
    : )
}

# A repo GitButler opened once and left a data dir in, still on a normal
# branch: plain git, and no `but` call.
mkrepo "$tmp/stale" main gb
cd "$tmp/stale" || exit 1
check "stale-renders-git" "🌿 main" "$(main)"
check "stale-no-but-call" "0" "$(cat "$stubcount")"

# A managed repo: HEAD parked on the workspace branch.
mkrepo "$tmp/managed" gitbutler/workspace gb
cd "$tmp/managed" || exit 1
check "managed-renders-butler" "⧓ my-feature ↑1" "$(main)"
check "managed-calls-but" "1" "$(cat "$stubcount")"

# GitButler's older workspace branch name.
mkrepo "$tmp/legacy" gitbutler/integration gb
cd "$tmp/legacy" || exit 1
check "legacy-renders-butler" "⧓ my-feature ↑1" "$(main)"

# A workspace branch name alone isn't enough without the data dir.
mkrepo "$tmp/nodir" gitbutler/workspace
cd "$tmp/nodir" || exit 1
check "no-dir-renders-git" "🌿 gitbutler/workspace" "$(main)"

# Plain repo, untouched by GitButler.
mkrepo "$tmp/plain" main
cd "$tmp/plain" || exit 1
check "plain-renders-git" "🌿 main" "$(main)"

# The predicate on its own: detached HEAD is not a workspace.
cd "$tmp/managed" || exit 1
git checkout -q --detach HEAD
if in_butler_workspace; then
  echo "FAIL - detached-not-workspace"; fail=1
else
  echo "ok   - detached-not-workspace"
fi

cd "$tmp" || exit 1
exit $fail
