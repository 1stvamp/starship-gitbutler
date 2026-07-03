# Changelog

Notable changes to this project. The format follows [Keep a Changelog](https://keepachangelog.com/), and versions follow [semver](https://semver.org/).

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

[1.1.0]: https://github.com/1stvamp/starship-gitbutler/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/1stvamp/starship-gitbutler/releases/tag/v1.0.0
