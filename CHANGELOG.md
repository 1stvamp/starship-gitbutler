# Changelog

Notable changes to this project. The format follows [Keep a Changelog](https://keepachangelog.com/), and versions follow [semver](https://semver.org/).

## [Unreleased]

### Fixed
- `but` 0.22.0 renamed the status json flag from `--format json` to `--json`, so the call failed outright and every butler repo read `⧓ workspace`. Nothing announced it: the script sends `but`'s stderr to /dev/null and treats empty output as an unapplied workspace, which is the same thing it prints when you genuinely have no branches applied. The script asks for `--json` now.

### Added
- A test that runs the arguments we hand `but` past the installed cli, so a renamed flag fails the suite rather than quietly degrading the segment. It skips when `but` isn't on PATH, which is the case in CI.

### Requirements
- `but` 0.22.0 or newer. There's no release that accepts both spellings of the flag, so older clis fail the read.

## [1.1.1] - 2026-09-10

### Fixed
- A repo the GitButler app had merely opened once showed `⧓ workspace` forever. The app leaves a `.git/gitbutler` dir behind when it's done, and the dir on its own was enough to pick the butler renderer. A repo now counts as managed only when HEAD is also parked on a `gitbutler/*` branch, which is what `but status` itself insists on, so plain repos get their `🌿 <branch>` back.
- The cache keys on the mtime of `.git/gitbutler/REFRESH`, and a repo with no REFRESH file gave it no key at all, so nothing was read or written and every redraw shelled out to `but`. Those entries now fall back to a write time that expires after 5 seconds, overridable with `BUT_CACHE_TTL`.

## [1.1.0] - 2026-07-03

### Changed
- The butler symbol is now ⧓ (U+29D3, bowtie), matching GitButler's mark, in place of the top hat.
- The ⧓ is coloured by the script itself: light blue on a dark terminal, dark blue on a light one. It works out the terminal background once per session via an OSC 11 query (cached), and falls back to dark; `GITBUTLER_PROMPT_MODE=light|dark` forces it. Because the colour now comes from the script, the custom module drops starship's static `$style` (`format = "$output "`).

### Added
- CI workflow running the test suite and shellcheck on push and pull requests.
- A prompt screenshot in the README.

## [1.0.0] - 2026-06-29

### Added
- First release. A starship `custom` module that reads applied GitButler stacks from `but status --format json` and renders them as `<symbol> name ↑N`, joined with ` | ` (or `workspace` when nothing's applied), and falls back to the plain git branch outside a butler repo.
- REFRESH-mtime cache keyed on the absolute gitbutler dir path, plus a `BUT_TIMEOUT` guard so a hung `but` can't stall the prompt.
- `install.sh`, a plain-bash test suite, and an Apache 2.0 license.

[Unreleased]: https://github.com/1stvamp/starship-gitbutler/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/1stvamp/starship-gitbutler/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/1stvamp/starship-gitbutler/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/1stvamp/starship-gitbutler/releases/tag/v1.0.0
