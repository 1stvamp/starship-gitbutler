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

check "none"      "⧓ workspace"                       "$(render_butler < "$DIR/tests/fixtures/none.json")"
check "one"       "⧓ my-feature ↑1"                   "$(render_butler < "$DIR/tests/fixtures/one.json")"
check "two"       "⧓ my-feature ↑1 | hotfix-login"    "$(render_butler < "$DIR/tests/fixtures/two.json")"
# Unparseable json is a failed read, so it must not pass for an empty workspace.
check "malformed" "⧓ ?"                               "$(render_butler < "$DIR/tests/fixtures/malformed.json")"
# A structurally-odd stack (missing branches) is skipped; well-formed stacks still render.
check "partial"   "⧓ good-branch ↑2"                  "$(render_butler < "$DIR/tests/fixtures/partial.json")"

# A non-zero exit from `but` wins regardless of what landed on stdout. This is
# the case that hid the --format/--json rename: the cli errored, stdout was
# empty, and the segment read as a perfectly ordinary empty workspace.
check "but-failed-empty"  "⧓ ?" "$(printf '' | render_butler 2)"
check "but-failed-output" "⧓ ?" "$(render_butler 2 < "$DIR/tests/fixtures/one.json")"
# Clean exit, valid json, nothing applied: the one case that means "workspace".
check "clean-empty"       "⧓ workspace" "$(render_butler 0 < "$DIR/tests/fixtures/none.json")"

exit $fail
