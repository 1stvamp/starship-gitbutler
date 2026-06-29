#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR/gitbutler-branch.sh"

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   - $1"; else echo "FAIL - $1: expected [$2] got [$3]"; fail=1; fi; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q -b main .
git config user.email t@t.t; git config user.name t
echo x > x; git add x; git commit -q -m init

check "branch" "🌿 main" "$(render_git)"

sha="$(git rev-parse --short HEAD)"
git checkout -q --detach HEAD
check "detached" "🌿 $sha" "$(render_git)"

# detection: plain repo has no gitbutler dir
check "no-butler-dir" "" "$(gitbutler_dir)"

exit $fail
