# Auto4Git

**Intelligent Git Automation with SSH Authentication**

Auto4Git is a shell script that simplifies and automates the process of
committing, pushing, and creating tags in Git, with full SSH authentication
validation, an interactive SSH setup wizard, identity configuration,
and i18n support.

![Version](https://img.shields.io/badge/version-0.0.5-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Shell](https://img.shields.io/badge/shell-bash-lightgrey)
![Platform](https://img.shields.io/badge/platform-linux-orange)
![i18n](https://img.shields.io/badge/i18n-pt__BR%20%7C%20en__US-purple)

## Features

- **Intuitive interactive mode** — Run without arguments and be guided step by step
- **SSH setup wizard** — Guides the user through SSH key creation and GitHub
  configuration when no key is found or authentication fails
- **Automatic SSH validation** — Verifies and loads SSH keys automatically
- **GitHub connection test** — Validates authentication before any operation
- **Identity configuration** — Detects and configures Git name/email interactively
- **Multi-line input** — Paste text directly or provide a file path
- **HTTPS → SSH conversion** — Converts remote URLs automatically
- **Mandatory annotated tags** — Always requires semantic versioning tags
- **ASCII art banner** — Displayed on every run and on `--help`
- **Error handling** — Validation at every step of the process
- **Legacy compatibility** — Supports `--tag`, `--msgtag`, `--msgcommit` arguments
- **i18n support** — `pt_BR` (default) and `en_US` (fallback), auto-detected

## Prerequisites

- Git installed
- Bash 4.0 or higher
- SSH key configured *(the wizard can set one up for you)*
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

The script guides you through 3 steps:

1. **Tag** — Enter the semantic version (e.g. `v1.2.3`)
2. **Tag message** — Describe what this release contains
3. **Commit message** — Describe the changes being committed

### Legacy Mode

```bash
./auto4git.sh --tag v1.2.3 --msgtag .msgtag --msgcommit .msgcommit
```

### Help

```bash
./auto4git.sh --help
```

## Options

| Option | Description |
|---|---|
| `--tag` | Tag version (e.g. `v1.0.0`) |
| `--msgtag` | File with tag message |
| `--msgcommit` | File with commit message |
| `-h, --help` | Show this help |

## SSH Setup Wizard

When no SSH key is found or authentication fails, Auto4Git automatically
launches an interactive wizard instead of displaying a static tutorial.

The wizard walks you through **6 steps**:

| Step | Action |
|---|---|
| 1 | Generate SSH key (ed25519) |
| 2 | Start ssh-agent |
| 3 | Add key to ssh-agent |
| 4 | Copy public key |
| 5 | Add key to GitHub |
| 6 | Test connection *(runs automatically)* |

Each step shows the exact commands to run. Press `ENTER` when done
or `s` to skip. The final step tests the connection automatically
and reports the result.

## Internationalization (i18n)

Auto4Git detects the system locale from `$LANG` / `$LC_ALL` and displays
all messages in the appropriate language. All strings live inside the
`i18n_get()` function at the end of the script.

| Locale | Status |
|---|---|
| `pt_BR` | Default |
| `en_US` | Fallback |
| others | Falls back to `pt_BR` |

To add a new locale, extend the `case` block inside `i18n_get()`.

## Execution Flow
Start │ ├── SSH Validation │ ├── Test GitHub connection │ │ └── [fail] → SSH Setup Wizard │ ├── Check ssh-agent │ └── Load SSH keys │ └── [none found] → SSH Setup Wizard │ ├── Git Validation │ ├── Check Git repository │ ├── Check Git identity │ ├── Check remote URL (HTTPS → SSH) │ └── Detect modifications │ ├── Mode Selection │ ├── Interactive (no arguments) │ └── Legacy (--tag --msgtag --msgcommit) │ └── Execution ├── [1/5] git add . ├── [2/5] git commit ├── [3/5] git tag -a ├── [4/5] git push origin └── [5/5] git push origin

## Project Structure

Auto4Git/ ├── auto4git.sh # Main script (includes i18n strings) ├── .gitignore # Git ignore rules ├── README.md # This file ├── CHANGELOG.md # Version history └── LICENSE # MIT License

## Troubleshooting

### No SSH key found / Authentication failed
The SSH setup wizard launches automatically. Follow the 6 steps
to generate, load, and register your key with GitHub.

### Remote is HTTPS
The script offers automatic conversion. To do it manually:

```bash
git remote set-url origin git@github.com:user/repo.git
```

### Git identity not configured
The script detects your GitHub username and SSH key email,
then prompts you to confirm or enter them manually.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

**Sandro Dias** (gitdias)
- GitHub: [@gitdias](https://github.com/gitdias)
- Contact: pro.sandrodias@gmail.com
- Repository: [Auto4Git](https://github.com/gitdias/Auto4Git)

