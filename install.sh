#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.config/starship"
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
format = "[$output]($style) "
style = "grey"
disabled = false
SNIP
