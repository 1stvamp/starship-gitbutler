#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.config/starship"
if [ ! -f "$REPO/gitbutler-branch.sh" ]; then
  echo "error: $REPO/gitbutler-branch.sh not found; refusing to create a dangling symlink" >&2
  exit 1
fi
mkdir -p "$DEST_DIR"
ln -sf "$REPO/gitbutler-branch.sh" "$DEST_DIR/gitbutler-branch.sh"
echo "Linked $DEST_DIR/gitbutler-branch.sh -> $REPO/gitbutler-branch.sh"
cat <<'SNIP'

Add to ~/.config/starship.toml:

  1. Replace `$git_branch` in `format` with `${custom.gitbutler}`.
  2. Add this table:

[custom.gitbutler]
command = "~/.config/starship/gitbutler-branch.sh"
when = true
shell = ["bash", "--noprofile", "--norc"]
format = "$output "
disabled = false
SNIP
