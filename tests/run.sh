#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rc=0
# Bypass git template dir that forces 'latest' branch in test environment
export GIT_TEMPLATE_DIR=/dev/null
for t in "$DIR"/test_*.sh; do
  echo "== $(basename "$t") =="
  bash "$t" || rc=1
done
exit $rc
