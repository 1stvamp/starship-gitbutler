#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR/gitbutler-branch.sh"

fail=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then echo "ok   - $1";
  else echo "FAIL - $1: expected [$2] got [$3]"; fail=1; fi
}

check "none"      "🦋 workspace"                       "$(render_butler < "$DIR/tests/fixtures/none.json")"
check "one"       "🦋 my-feature ↑1"                   "$(render_butler < "$DIR/tests/fixtures/one.json")"
check "two"       "🦋 my-feature ↑1 | hotfix-login"    "$(render_butler < "$DIR/tests/fixtures/two.json")"
check "malformed" "🦋 workspace"                       "$(render_butler < "$DIR/tests/fixtures/malformed.json")"
# A structurally-odd stack (missing branches) is skipped; well-formed stacks still render.
check "partial"   "🦋 good-branch ↑2"                  "$(render_butler < "$DIR/tests/fixtures/partial.json")"

exit $fail
