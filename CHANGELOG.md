# Changelog

All notable changes in this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),

and this project adheres to [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Planned
- Support for multiple remote repositories
- Interactive mode for file selection
- Integration with GitLab and Bitbucket
- ​​Configuration via .auto4gitrc file
- Verbose mode for debugging
- Support for custom hooks

---

## [0.0.1] - 2026-02-14

### 🎉 Initial Release

This is the first stable version of Auto4Git!

### Added
- **Full SSH Validation**

- Automatic ssh-agent verification

- Automatic loading of SSH keys (ed25519, RSA, ECDSA)

- GitHub connection test before operations

- **Git Identity Configuration**

- Automatic GitHub user detection

- SSH key email detection

- Interactive name and email configuration

- Global or local configuration option

- **Remote Management**

- HTTPS URL detection

- Automatic HTTPS → SSH conversion

- Remote origin validation

- **Commit Automation**

- Support for commit messages in external files

- Automatic addition of all modified files

- Validation of modifications before commit

- **Tag Support**

- Annotated tag creation

- Tag duplication check

- Automatic push of tags to remote

- Tag message identical to the commit

- **User Interface**

- Colored output (green, yellow, blue, red)

- Informative messages at each stage
- Progress indicators [1/4], [2/4], etc.
- Presentation banner

- Final summary of operations

- **Error handling**

- Argument validation

- File existence verification

- Email format validation

- Timeout on SSH connections

- Clear error messages with troubleshooting tips

- **Documentation**

- Complete README.md

- Usage examples

- Troubleshooting guide

- Structured CHANGELOG.md

### Security
- SSH authentication validation before push
- Git identity verification before commit
- Security timeout on SSH connections

---

## Versioning Conventions

This project follows [Semantic Versioning](https://semver.org/lang/pt-BR/):

- **MAJOR** (X.0.0): Incompatible changes in the API
- **MINOR** (0.X.0): New features while maintaining compatibility
- **PATCH** (0.0.X): Bug fixes and Improvements

## Types of Changes

- **Added** - for new features
- **Modified** - for changes to existing features
- **Discontinued** - for features that will be removed
- **Removed** - for removed features
- **Fixed** - for bug fixes
- **Security** - for vulnerabilities fixed

---

[Unreleased]: https://github.com/gitdias/Auto4Git/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/gitdias/Auto4Git/releases/tag/v0.0.1