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

## [0.0.4] - 2026-03-14

### 🌍 i18n Support, `.gitignore` and Documentation Migration

This version introduces full internationalisation (i18n), adds a `.gitignore`
file, and migrates the documentation to English as the canonical language.

### Added

#### Internationalisation (i18n)
- **Locale detection**
  - Detects system locale from `LANG`, `LC_ALL` or `LC_MESSAGES`
  - Normalises values (case, hyphen/underscore, encoding)
  - Maps common variants (`pt`, `pt_BR`, `en`, `en_US`, `en_GB`, etc.) to
    internal locales

- **Supported locales**
  - `pt_BR` as the **default** locale
  - `en_US` as the **fallback** locale
  - All other locales first try `pt_BR` and then gracefully fall back to `en_US`

- **Key–value i18n system**
  - New `detect_locale()` function to determine the current locale
  - New translation helpers:
    - `t(key)` — returns the translated message for the active locale
    - `i18n_get(locale, key)` — key→value store for each supported locale
  - All user-facing strings moved behind `t(...)` keys
    (no message is left outside the i18n system)
  - Structured keys by domain (e.g. `usage.*`, `ssh.*`, `git.*`,
    `interactive.*`, `proc.*`, `summary.*`, etc.)

#### `.gitignore`
- New `.gitignore` file including:
  - `.msgtag` / `.msgcommit` and `*.msgtag` / `*.msgcommit`
  - Editor and IDE folders (`.vscode/`, `.idea/`, `*.code-workspace`)
  - Temporary files (`*.tmp`, `*.bak`, `*.swp`, `*.swo`, `*~`)
  - OS-specific files (`.DS_Store`, `Thumbs.db`)
  - Generic log and test artefacts (`*.log`, `/test/`, `/tests/`)

#### Documentation (English as source of truth)
- README migrated to English:
  - Describes interactive and legacy modes
  - Documents i18n behaviour (pt_BR default, en_US fallback)
  - Updates version badge to `0.0.4`
- CHANGELOG migrated to English (this file), consolidating previous entries

### Changed

#### Script Header
- Header comments converted to technical English:
  - `Auto4Git - Git Automation with SSH`
  - Fields renamed to `Author`, `Contact`, `Repository`, `Version`, `License`,
    `Description`, `Syntax`
- `VERSION` variable updated from `0.0.3` to `0.0.4`

#### Messages and Output
- All hard-coded messages replaced by i18n keys:
  - SSH diagnostics (agent, keys, GitHub test)
  - Git validations (repository, identity, remote, modifications)
  - Interactive prompts and examples
  - Legacy mode errors and summaries
  - Processing steps and final summary
- SSH tutorial content i18n-ised in both `pt_BR` and `en_US`,
  keeping the same instructional steps

### Removed

- Any remaining Portuguese-only messages in the script body
  (now all go through the i18n layer)

---

## [0.0.3] - 2026-03-13

### 🎨 Visual Identity and Encoding Fixes

This version focuses on the Auto4Git visual identity, with the introduction
of a new ASCII art banner, and on fixing all corrupted characters caused by
encoding issues in v0.0.2.

### Added

#### Visual Interface
- **New ASCII art banner**
  - Auto4Git logo rendered as ASCII art in the terminal:
    - `show_banner()` now prints a multi-line logo
    - Version displayed dynamically via `${VERSION}`
    - Decorative separator line:
      `─────────────────────────────|___/ v${VERSION}`
  - Replaces the generic boxed banner from v0.0.2

- **Banner in `--help`**
  - `show_usage()` now calls `show_banner()` at the top
  - Consistent visual identity across all entry points

### Changed

#### Script Header
- Header comments translated to **technical English**:
  - `Automaçao Git com SSH` → `Git Automation with SSH`
  - Localised field names (Author, Contact, Repository, Version, License,
    Description, Syntax)

#### SSH Tutorial
- Hardcoded hostname `CachyOS` replaced by dynamic `$(hostname)` in the
  suggested SSH key title for GitHub

### Fixed

#### Encoding and Box-Drawing Characters
- **UTF-8 encoding fully corrected:**
  - All corrupted sequences (`ГЈo`, `ГЎ`, `Г³`, etc.) restored to proper UTF-8
    (`ão`, `á`, `ó`, etc.) throughout the script
  - Corrupted box-drawing characters replaced with clean ASCII/UTF-8
    equivalents (e.g. `════`, `────`)
  - Eliminates artefacts introduced by previous encoding conversions in v0.0.2

---

## [0.0.2] - 2026-02-17

### 🎉 Interactive Mode Implemented

This version is a significant evolution of Auto4Git, introducing the
interactive mode as the default while keeping full backward compatibility
with the previous version.

### Added

#### Interface and Usability
- **Interactive mode as default**
  - Simplified execution with `./auto4git.sh` (no mandatory arguments)
  - Step-by-step guided flow for tag, tag message and commit message
  - Improved visual interface with ASCII banners and separators
  - Clear progression with indicators like `[1/5]`, `[2/5]`, etc.

- **Improved multi-line input**
  - Support for pasting text directly into the terminal
  - End input with `Ctrl+D`
  - Alternative: provide a file path
  - Smart detection between direct text input and file path

- **Full SSH tutorial**
  - Automatically displayed when authentication fails
  - 5-step visual walkthrough
  - Boxed formatting for better readability
  - Ready-to-copy commands
  - Direct links and instructions for GitHub configuration

#### Validation and Safety
- **Tag format validation**
  - Enforces semantic versioning (e.g. `v1.2.3`, `v2.0.0-beta`)
  - Detects duplicate tags before creation
  - Clear error messages with correction hints

- **Mandatory tags**
  - Tags are now mandatory in both interactive and legacy modes
  - Always creates annotated tags with dedicated messages
  - Clear separation between tag message and commit message

- **Improved SSH validation**
  - 10-second timeout to avoid hangs
  - More robust failure detection
  - More descriptive error messages

#### Compatibility
- **New `--tagmsg` argument**
  - Keeps full compatibility with v0.0.1
  - Legacy syntax:
    `--tag <version> --tagmsg <file> --msg <file>`
  - All three arguments are mandatory in legacy mode

- **Automatic mode detection**
  - No arguments: interactive mode
  - With arguments: legacy mode (v0.0.1 compatibility)

### Changed

#### Visual Interface
- **Redesigned initial banner**
  - Box-style ASCII art
  - Centered and highlighted version
  - Clear visual identification for Auto4Git

- **Output organisation**
  - Well-separated sections with horizontal lines
  - Consistent colour usage:
    - Green (success), Yellow (warnings), Blue (info), Red (errors)
  - Icons/symbols for quick identification (✓, →, etc.)

- **Progress messages**
  - Clear numeric indicators `[X/N]`
  - More detailed description per step
  - Immediate feedback on success or failure

#### Execution Flow
- **Validation ordering**
  - SSH validated before Git
  - Git identity validated before remote URL
  - Modifications validated last

- **Separation of responsibilities**
  - Dedicated function for interactive mode
  - Dedicated function for SSH tutorial
  - Modular, reusable validation functions

### Fixed

- **SSH key detection**
  - Correct priority order (ed25519 > rsa > ecdsa)
  - Improved error handling when adding keys
  - Clearer feedback when a passphrase is required

- **Empty file validation**
  - Checks for both existence and content
  - Specific error messages per scenario

- **HTTPS → SSH conversion**
  - Clearer prompt with highlighted `(s/N)`
  - Validation before allowing continuation with HTTPS

### Documentation

- **README.md updated**
  - Added interactive mode section
  - Examples updated to show the new flow
  - Expanded troubleshooting section
  - Conceptual screenshots/flow description

- **CHANGELOG.md created**
  - Complete history since v0.0.1
  - Uses the Keep a Changelog format
  - Clear categories (Added, Changed, Fixed)

### Performance

- **Validation optimisations**
  - SSH connection timeout to avoid infinite waits
  - Cached GitHub user detection
  - Validations executed only when necessary

---

## [0.0.1] - 2026-02-14

### 🎉 Initial Release

First stable release of Auto4Git.

### Added

- **Full SSH validation**
  - Automatic `ssh-agent` detection
  - Automatic loading of SSH keys (ed25519, RSA, ECDSA)
  - GitHub connection test before any operation

- **Git identity configuration**
  - Automatic GitHub user detection
  - SSH key email extraction
  - Interactive setup for name and email
  - Option to configure globally or locally

- **Remote management**
  - HTTPS remote URL detection
  - Automatic HTTPS → SSH conversion
  - `origin` remote validation

- **Commit automation**
  - Support for external commit message files
  - Automatic staging of all modified files
  - Validation for pending changes before committing

- **Tag support**
  - Creation of annotated tags
  - Duplicate tag detection
  - Automatic push of tags to remote
  - Tag message equal to commit message (v0.0.1 behaviour)

- **User interface**
  - Coloured output (green, yellow, blue, red)
  - Informative messages at each step
  - Progress indicators `[1/4]`, `[2/4]`, etc.
  - Introductory banner
  - Final summary of operations

- **Error handling**
  - Argument validation
  - File existence checks
  - Email format validation
  - SSH timeout safeguards
  - Clear error messages with hints

- **Documentation**
  - Complete README
  - Usage examples
  - Troubleshooting guide
  - Structured CHANGELOG

### Security

- SSH authentication validated before any push
- Git identity checked before committing
- Safety timeout for SSH connections

---

## Versioning Conventions

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Incompatible API changes
- **MINOR** (0.X.0): New functionality while maintaining compatibility
- **PATCH** (0.0.X): Bug fixes and backwards-compatible improvements

## Types of Changes

- **Added** – for new features
- **Changed** – for changes in existing functionality
- **Deprecated** – for soon-to-be removed features
- **Removed** – for now removed features
- **Fixed** – for any bug fixes
- **Security** – in case of vulnerabilities
- **Documentation** – for documentation improvements
- **Performance** – for performance optimisations

---

[Unreleased]: https://github.com/gitdias/Auto4Git/compare/v0.0.4...HEAD
[0.0.4]: https://github.com/gitdias/Auto4Git/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/gitdias/Auto4Git/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/gitdias/Auto4Git/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/gitdias/Auto4Git/releases/tag/v0.0.1