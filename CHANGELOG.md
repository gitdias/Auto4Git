# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Support for multiple remote repositories
- Dry-run mode to preview operations without executing
- GitLab and Bitbucket integration
- Configuration via `.auto4gitrc` file
- Verbose mode for detailed debugging
- Custom hook support (pre-commit, post-push)
- Conventional Commits validation
- Automatic CHANGELOG generation

---

## [0.0.5] - 2026-03-14

### 🧙 SSH Setup Wizard and Argument Renaming

This release replaces the static SSH tutorial with an interactive SSH setup
wizard that guides the user step by step through SSH configuration, checking
completion at each phase. The legacy mode arguments are renamed to match the
project file naming conventions.

### Added

#### SSH Setup Wizard
- **`show_ssh_wizard()`** replaces `show_ssh_tutorial()`
  - Informs the user clearly that no SSH key was detected on the system
  - Asks whether the user wants to configure a new key before proceeding
  - If declined, exits gracefully with an informational message
  - Runs a **6-step interactive loop** with a live status panel:
    - `[✓]` completed — `[→]` current — `[ ]` pending
  - Steps covered:
    1. Generate SSH key (ed25519)
    2. Start ssh-agent
    3. Add key to ssh-agent
    4. Copy public key
    5. Add key to GitHub
    6. Test GitHub connection *(executed automatically)*
  - Each step displays commands and hints, then waits for `ENTER`
    or `s` to skip
  - Step 6 runs `ssh -T git@github.com` automatically and reports
    success or failure; exits with code 1 if still failing
- **`_wizard_menu(locale, current, states[])`**
  - Renders the step status panel before each step
  - Updates markers dynamically as steps are completed or skipped
- **`_wizard_instructions(step)`**
  - Prints the specific commands and hints for a given step index
- New **`wizard.*` i18n key domain** covering all wizard strings
  in both `pt_BR` and `en_US`:
  - `wizard.no_key_header`, `wizard.no_key_detail`, `wizard.ask_setup`
  - `wizard.title`, `wizard.menu_title`
  - `wizard.step_done`, `wizard.step_todo`, `wizard.step_current`
  - `wizard.prompt_next`, `wizard.skipped`
  - `wizard.completed`, `wizard.success`, `wizard.still_fail`, `wizard.exit_fail`
  - `wizard.aborted`
  - `wizard.s1.*` through `wizard.s6.*` (labels, commands, hints)

### Changed

#### Argument Renaming (Legacy Mode)
- `--tagmsg` renamed to **`--msgtag`** — reads the tag message file
- `--msg` renamed to **`--msgcommit`** — reads the commit message file
- Legacy mode syntax updated:
  ```
  ./auto4git.sh --tag <version> --msgtag <file> --msgcommit <file>
  ```
- `show_usage()` updated with new argument names and example
- i18n keys updated: `usage.opt.msgtag`, `usage.opt.msgcommit`,
  `legacy.required`

#### SSH Validation Flow
- `check_ssh_keys_loaded()` now calls `show_ssh_wizard()` instead of
  printing a warning and continuing when no key is found
- `test_github_ssh()` now calls `show_ssh_wizard()` instead of
  `show_ssh_tutorial()` on authentication failure

### Removed
- **`show_ssh_tutorial()`** — replaced entirely by `show_ssh_wizard()`

---

## [0.0.4] - 2026-03-14

### 🌍 i18n Support, `.gitignore` and Documentation Migration

This version introduces full internationalisation (i18n), adds a `.gitignore`
file, and migrates all documentation to English as the canonical language.

### Added

#### Internationalisation (i18n)
- **Locale detection** via `detect_locale()`
  - Reads `$LANG`, `$LC_ALL` or `$LC_MESSAGES`
  - Normalises values (case, hyphen/underscore, encoding suffix)
  - Maps variants (`pt`, `pt_BR`, `en`, `en_US`, `en_GB`, etc.)
- **Supported locales**
  - `pt_BR` — default
  - `en_US` — fallback
  - All other locales fall back to `pt_BR` then `en_US`
- **Translation helpers**
  - `t(key)` — returns translated message for the active locale
  - `i18n_get(locale, key)` — key→value store per locale
- **i18n key domains** covering every user-facing string:
  `prefix.*`, `usage.*`, `ssh.*`, `tutorial.*`, `git.*`,
  `interactive.*`, `input.*`, `tag.*`, `legacy.*`,
  `proc.*`, `section.*`, `summary.*`

#### `.gitignore`
- Covers: `.msgtag`, `.msgcommit`, `*.msgtag`, `*.msgcommit`
- Editor/IDE folders: `.vscode/`, `.idea/`, `*.code-workspace`
- Temporary files: `*.tmp`, `*.bak`, `*.swp`, `*.swo`, `*~`
- OS-specific: `.DS_Store`, `Thumbs.db`
- Logs and test artefacts: `*.log`, `/test/`, `/tests/`

### Changed
- Script header comments converted to technical English
- `VERSION` updated to `0.0.4`
- All hard-coded messages replaced by `t()` i18n calls
- README migrated to English with i18n section and updated badges
- CHANGELOG consolidated, translated to English, and reorganised
  (v0.0.1 through v0.0.4)

---

## [0.0.3] - 2026-03-13

### 🎨 Visual Identity and Encoding Fixes

### Added
- **New ASCII art banner** in `show_banner()`
  - Auto4Git logo rendered as multi-line ASCII art
  - Version displayed dynamically via `${VERSION}`
  - Separator line: `─────────────────────────────|___/ v${VERSION}`
- **Banner in `--help`** — `show_usage()` now calls `show_banner()` at the top

### Changed
- Script header comments translated to technical English
- Hardcoded hostname `CachyOS` replaced by dynamic `$(hostname)`
  in the SSH key title suggestion

### Fixed
- **UTF-8 encoding fully corrected** throughout the script
  - Corrupted sequences (`ГЈo`, `ГЎ`, `Г³`, etc.) restored to proper UTF-8
  - Corrupted box-drawing characters replaced with clean `════` / `────`

---

## [0.0.2] - 2026-02-17

### 🎉 Interactive Mode Implemented

### Added
- **Interactive mode as default** (`./auto4git.sh` with no arguments)
  - Step-by-step guided flow: tag → tag message → commit message
  - Progress indicators `[1/5]`, `[2/5]`, etc.
- **Improved multi-line input** — paste text or provide a file path;
  end with `Ctrl+D`
- **Full SSH tutorial** — displayed automatically on authentication failure;
  5-step walkthrough with ready-to-copy commands
- **Tag format validation** — enforces semantic versioning; detects duplicates
- **Mandatory annotated tags** — required in both interactive and legacy modes
- **`--tagmsg` argument** for legacy mode compatibility
- **Automatic mode detection** — no args → interactive; args → legacy

### Changed
- Banner redesigned to box-style ASCII art
- Output organised into well-separated sections with consistent
  colour usage (green/yellow/blue/red)
- Validation ordering: SSH → Git identity → remote URL → modifications
- Dedicated functions for interactive mode and SSH tutorial

### Fixed
- SSH key priority order corrected (ed25519 > rsa > ecdsa)
- Empty file validation now checks content, not just existence
- HTTPS → SSH conversion prompt clarified

### Performance
- SSH connection timeout to avoid infinite waits
- Cached GitHub user detection
- Validations executed only when necessary

---

## [0.0.1] - 2026-02-14

### 🎉 Initial Release

First stable release of Auto4Git.

### Added
- Full SSH validation (ssh-agent, key loading, GitHub connection test)
- Git identity configuration with GitHub user and SSH email detection
- Remote management with HTTPS → SSH conversion
- Commit automation with external message file support
- Annotated tag creation with duplicate detection and auto-push
- Coloured output, progress indicators, and final summary
- Error handling with clear messages and hints at every step
- Complete README, usage examples, troubleshooting guide and CHANGELOG

### Security
- SSH authentication validated before any push
- Git identity verified before committing
- Safety timeout for all SSH connections

---

## Versioning Conventions

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Incompatible API changes
- **MINOR** (0.X.0): New functionality, backwards-compatible
- **PATCH** (0.0.X): Bug fixes and backwards-compatible improvements

## Types of Changes

- **Added** — new features
- **Changed** — changes in existing functionality
- **Deprecated** — soon-to-be removed features
- **Removed** — removed features
- **Fixed** — bug fixes
- **Security** — vulnerability fixes
- **Performance** — performance optimisations

---

[Unreleased]: https://github.com/gitdias/Auto4Git/compare/v0.0.5...HEAD
[0.0.5]: https://github.com/gitdias/Auto4Git/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/gitdias/Auto4Git/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/gitdias/Auto4Git/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/gitdias/Auto4Git/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/gitdias/Auto4Git/releases/tag/v0.0.1