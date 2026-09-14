#!/usr/bin/env bash
# Checks the arguments we actually hand to `but` against the installed binary.
# The other suites stub but_status_json, so nothing there notices when the CLI
# renames a flag; that is how `--format json` rotted into a silent "workspace".
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$DIR/gitbutler-branch.sh"

fail=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then echo "ok   - $1";
  else echo "FAIL - $1: expected [$2] got [$3]"; fail=1; fi
}

# Capture the real invocation by shadowing `but` on PATH: the timeout branch
# execs a binary, so a shell function wouldn't be seen.
stub="$(mktemp -d)"
cat > "$stub/but" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*"
STUB
chmod +x "$stub/but"
args="$(PATH="$stub:$PATH" but_status_json 2>/dev/null)"
rm -rf "$stub"

check "passes status subcommand" "status" "${args%% *}"

if ! command -v but >/dev/null 2>&1; then
  echo "skip - but not installed, cannot verify flags against the CLI"
  exit $fail
fi

help="$(but status --help 2>&1)"
for flag in ${args#status}; do
  case "$flag" in -*) ;; *) continue ;; esac
  case "$help" in
    *"$flag"*) echo "ok   - but status accepts $flag" ;;
    *) echo "FAIL - but status does not accept $flag (CLI $(but --version 2>&1))"; fail=1 ;;
  esac
done

exit $fail
