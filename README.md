# starship-gitbutler

A starship prompt segment that knows about GitButler. In a butler repo it shows the virtual branches (stacks) you actually have applied, with how far ahead each one is; everywhere else it behaves like the normal git branch module.

The reason it exists: when you turn a repo into a GitButler project you get parked on a `gitbutler/workspace` branch, so starship's built-in `git_branch` just prints `gitbutler/workspace` and tells you nothing about what you're working on. This swaps that out for the real picture, pulled from the `but` cli.

```
🎩 my-feature ↑3 | hotfix-login ↑1     # butler repo, two stacks applied
🎩 workspace                            # butler repo, nothing applied yet
🌿 main                                 # ordinary git repo
```

The 🎩 is for GitButler (their mark is a butler bowtie, not the butterfly I first reached for), 🌿 is the plain git branch. Both are easy to change at the top of the script.

## How it works

starship is a single compiled binary with no plugin system, so this isn't a fork of the git module.. it's a `custom` module backed by a small bash script (`gitbutler-branch.sh`). The script does the deciding:

- it checks for a `.git/gitbutler` directory. If that's there it reads the applied stacks out of `but status --format json` and renders `🎩 name ↑N` per branch, joined with ` | `.
- otherwise it falls back to `git branch`, e.g. `🌿 main` (or the short sha when you're detached).
- outside a git repo it prints nothing, so the segment just disappears.

It always exits 0 and never prints a half-formed segment, so a broken `but`, dodgy json, or a missing cache file can't take your prompt down with it.

## Caching

`but status` is around 200ms, which is too slow to run on every redraw. So the script caches its output keyed on the mtime of `.git/gitbutler/REFRESH`, the file gitbutler bumps whenever the workspace changes. While that file is unchanged you get the cached string back for nothing; when it moves, the script recomputes. The cache lives under `${XDG_CACHE_HOME:-~/.cache}/starship-gitbutler` and the key is the absolute path to the gitbutler dir, so moving between subdirectories of the same repo still hits the same entry.

There's also a 2s timeout around the `but` call (override with the `BUT_TIMEOUT` env var). If `but` ever hangs you get a quick `🎩 workspace` instead of a stalled prompt.

## Requirements

- starship
- the GitButler cli (`but`)
- jq
- git, bash

It uses GNU `stat` for the cache mtime and falls back to BSD `stat -f %m`, so linux and macos both work.

## Install

```bash
git clone https://github.com/1stvamp/starship-gitbutler.git
cd starship-gitbutler
./install.sh
```

`install.sh` symlinks the script into `~/.config/starship/` and prints the config snippet. Then in `~/.config/starship.toml`, replace `$git_branch` in your `format` string with `${custom.gitbutler}` and add the table:

```toml
[custom.gitbutler]
command = "~/.config/starship/gitbutler-branch.sh"
when = true
shell = ["bash", "--noprofile", "--norc"]
format = "[$output]($style) "
style = "grey"
disabled = false
```

Leave `$git_commit`, `$git_state` and `$git_status` where they are; they still make sense on the workspace. If you keep a separate starship profile (e.g. the Claude Code statusline) you'll want to swap `$git_branch` there too.

## Tests

Plain bash, no framework, just jq:

```bash
bash tests/run.sh
```

That covers the stack rendering against captured `but` json (none, one, several, malformed, and a partial stack), the git fallback and detached HEAD, repo detection, and the cache (hit, miss, recompute on REFRESH, and degrading to a direct call when the cache dir is unwritable).
