# Auto4Git

**Intelligent Git Automation with SSH Authentication**

Auto4Git is a shell script that simplifies and automates the process of
committing, pushing, and creating tags in Git, with full SSH authentication
validation, identity configuration, and i18n support.

![Version](https://img.shields.io/badge/version-0.0.4-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Shell](https://img.shields.io/badge/shell-bash-lightgrey)
![Platform](https://img.shields.io/badge/platform-linux-orange)
![i18n](https://img.shields.io/badge/i18n-pt__BR%20%7C%20en__US-purple)

## Features

- **Intuitive interactive mode** — Run without arguments and be guided step by step
- **Automatic SSH validation** — Verifies and configures SSH keys automatically
- **Didactic SSH tutorial** — Full visual help when authentication fails
- **GitHub connection test** — Validates authentication before any operation
- **Identity configuration** — Detects and configures Git name/email interactively
- **Multi-line input** — Paste text directly or provide a file path
- **HTTPS → SSH conversion** — Converts remote URLs automatically
- **Mandatory annotated tags** — Always creates tags with semantic versioning
- **Error handling** — Validation at every step of the process
- **Legacy compatibility** — Maintains support for v0.0.1 arguments
- **i18n support** — pt_BR (default) and en_US, auto-detected from system locale
- **ASCII art banner** — Auto4Git logotype displayed on every run and on --help

## Prerequisites

- Git installed.
- Bash 4.0 or higher
- SSH key configured (the script can guide you through the setup)
- GitHub access via SSH

## Installation

### Option 1: Clone the repository

```bash
git clone git@github.com:gitdias/Auto4Git.git
cd Auto4Git
chmod +x auto4git.sh
```

### Option 2: Direct download

```bash
curl -O https://raw.githubusercontent.com/gitdias/Auto4Git/main/auto4git.sh
chmod +x auto4git.sh
```

## Usage

### Interactive Mode (recommended)

```bash
./auto4git.sh
```

The script will guide you through 3 steps:

1. **Tag** — Enter the semantic version (e.g. `v1.2.3`)
2. **Tag message** — Describe what this release contains
3. **Commit message** — Describe the changes being committed

### Legacy Mode (v0.0.1 compatibility)

```bash
./auto4git.sh --tag v1.2.3 --tagmsg release.txt --msg commit.txt
```

### Help

```bash
./auto4git.sh --help
```

## Internationalization (i18n)

Auto4Git automatically detects the system locale via `$LANG` / `$LC_ALL`
and displays all messages in the appropriate language.
All strings are stored inside the script in the `i18n_get()` function.

| Locale  | Status           |
|---------|------------------|
| `pt_BR` | Default          |
| `en_US` | Fallback         |
| others  | Falls back to pt_BR |

To add a new locale, extend the `case` block inside `i18n_get()`.

## Execution Flow
Start │ ├── SSH Validation │ ├── Test GitHub connection │ ├── Check ssh-agent │ └── Load SSH keys │ ├── Git Validation │ ├── Check Git repository │ ├── Check Git identity │ ├── Check remote URL (HTTPS → SSH) │ └── Detect modifications │ ├── Mode Selection │ ├── Interactive (no arguments) │ └── Legacy (--tag --tagmsg --msg) │ └── Execution ├── [1/5] git add . ├── [2/5] git commit ├── [3/5] git tag -a ├── [4/5] git push origin └── [5/5] git push origin

## Project Structure

Auto4Git/ ├── auto4git.sh # Main script (includes i18n strings) ├── .gitignore # Git ignore rules ├── README.md # This file ├── CHANGELOG.md # Version history └── LICENSE # MIT License

## Troubleshooting

### SSH authentication failed
The script displays a full 5-step tutorial automatically.

### Remote is HTTPS
The script offers automatic conversion. To do it manually:

```bash
git remote set-url origin git@github.com:user/repo.git
```

### Git identity not configured
The script detects your GitHub username and SSH key email and
prompts you to confirm or enter them manually.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

**Sandro Dias** (gitdias)
- GitHub: [@gitdias](https://github.com/gitdias)
- Contact: pro.sandrodias@gmail.com
- Repository: [Auto4Git](https://github.com/gitdias/Auto4Git)
