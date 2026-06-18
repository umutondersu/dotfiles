# My Dotfiles for Linux

This repository contains my Linux configuration files managed with
[GNU Stow](https://www.gnu.org/software/stow/) for dotfile symlinking.

- **Distro-agnostic**: Works on all major Linux distribution with [Devbox](https://www.jetify.com/devbox)
- **Reproducible**: Same package versions across all machines via `devbox.json`
- **Isolated**: Doesn't interfere with system package manager
- **Simple**: One command to install everything

## Supported Distributions

The installation script automatically detects and supports:

- **Debian/Ubuntu-based**: Ubuntu, Pop!\_OS, Debian, Linux Mint, elementary OS
- **RHEL-based**: Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux
- **Arch-based**: Arch Linux, Manjaro, EndeavourOS, CachyOS
- **SUSE-based**: openSUSE, SLES
- **Alpine Linux**
- Other distributions work with manual prerequisites

**For now It is only reliably tested on Pop!\_OS, Fedora and CachyOS**

## Requirements

- **git**
- **curl**
- **sudo**
- **unzip** — optional for non-Arch Nerd Font installation on desktop

The install script should handle everything else (check [Prerequisites](#prerequisites))

## Installation

This repository offers two installation modes via a unified install script:

### Development Environment Installation (Default)

For development environments, SSH sessions, remote environments, containers,
and DevPods:

```bash
cd ~
git clone https://github.com/umutondersu/dotfiles.git
cd dotfiles
./install.sh
# or explicitly: ./install.sh --devenv
```

### Desktop Installation (Full Setup)

For workstations and desktop environments with GUI applications:

```bash
cd ~
git clone https://github.com/umutondersu/dotfiles.git
cd dotfiles
./install.sh --desktop
```

**Installation Options:**

- `--devenv` (default): Development environment with CLI tools
- `--desktop`: Full desktop environment with GUI tools

## What Gets Installed

### Prerequisites

The installation script automatically installs these prerequisites on
supported distributions:

- **GNU Stow**

If your distribution is not detected, you'll need to manually install them

### Devbox Packages

#### These might be old if I forgot to update the readme after editing packages

**Default Shell:**

- fish

**Shell & CLI Tools:**

- fzf, ripgrep, fd, zoxide, bat, lsd, tldr, direnv, glow, gh

**Development:**

- neovim, opencode, nodejs_22, deno

**Utilities:**

- curlie (HTTP client)
- posting (API client)
- vegeta (load testing)
- lazygit (git client)
- lazydocker (docker client)
- jq (JSON Processor)
- w3m (Terminal Web Browser)
- ncdu: Disk usage analyzer

### Desktop-Only Packages (with `--desktop`)

- **tmux**: Terminal multiplexer
- **streamrip**: Media downloader
- **yt-dlp**: Video downloader
- **sesh**: Smart Session Manager
- **gcm**: Git Credential Manager
- **fish-lsp**: Lsp Server for Fish

### Desktop-Only Flatpak Applications

Desktop installation includes Flatpak applications. During `./install.sh --desktop`,
you'll be prompted to install applications listed in `flatpak-apps.txt`.

Categories include browsers, development tools, media players, gaming emulators,
and utilities. To customize, edit `flatpak-apps.txt` before running the installer.

#### Manual Installations with scripts

- **kitty**: Terminal emulator (script in `setup/kitty.sh`)
- **vosk**: Speech recognition library (script in `setup/vosk-install.sh`)
- **TPM**: Tmux Plugin Manager (git clone to `~/.tmux/plugins/tpm`)
- **JetBrainsMono Nerd Font**: See [Nerd Font Installation](#nerd-font-installation) below

### Nerd Font Installation

Desktop installation (`--desktop`) automatically installs
**JetBrains Mono Nerd Font** via `setup/desktop/nerdfont.sh`.

- **Arch-based**: installed via `pacman` (`ttf-jetbrains-mono-nerd`)
- **Other distros**: downloaded from the [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases)
  and installed to `~/.local/share/fonts`

> **Note:** Non-Arch systems require `unzip` to extract the font archive.

## Devbox Configuration Approach

The devbox configuration uses a **template-based approach** rather than direct symlinking:

- **Template Location**: `devbox.json` (tracked in git)
- **Working Location**: `~/.local/share/devbox/global/default/devbox.json`
  (copied during installation)

### Why Copy Instead of Stow (Symlink)?

1. **Desktop-specific packages**: `install.sh --desktop` adds extra packages using
   `devbox global add` which creates a permanent dirty git with stow
2. **Environment flexibility**: Dev environments get the base config,
   desktop environments get base + extras

## Package Management

```bash
# Add new package
devbox global add <package-name>

# Remove package
devbox global rm <package-name>

# List installed packages
devbox global list

# Update all packages
devbox global update

# Search for packages
devbox search <query>
```

**To sync your changes with the template you can use `sync-devbox`.**

- 📦 **sync-devbox**: Fish function to sync devbox configurations bidirectionally.
  Default usage (`sync-devbox`) syncs working config → template, excluding desktop
  packages. Use `--from-template` or `-R` to restore working config
  from template and add desktop packages (requires confirmation unless `-f` or `--force`
  is used). Also supports `--dry-run` or `-n`

- 🖥️ **desktop-pkg**: Fish function to manage desktop-specific devbox packages
  defined in `desktop-packages.txt`. Supports `-i`/`--install` to install all packages
  (runs `setup/desktop/packages.sh`, also called directly by `./install.sh --desktop`),
  `-a`/`--append` to add a package (validates via `devbox search`, installs, then persists),
  `-r`/`--remove` to uninstall and remove from the file, `-l`/`--list` to list packages,
  and `-n`/`--dry-run`.

## macOS / Homebrew

On macOS, Homebrew packages are managed via `Brewfile` at the repo root. The install script
runs `brew bundle` automatically.

```bash
# Install all packages from Brewfile
brew bundle --file=Brewfile

# Update Brewfile with currently installed packages
brew bundle dump --file=Brewfile --force
```

The installer also creates `~/.gitconfig.local` to configure Git's credential helper
to use the macOS Keychain (`osxkeychain`).

## Testing

Automated Docker tests are available to verify the installation in a clean environment:

See [`setup/.test/TESTING.md`](setup/.test/TESTING.md) for detailed documentation.

## System Configuration

`etc/` and are automatically stowed to `/etc/` during desktop installation

The installation script checks for existing directories in `/etc/` and skips
stowing if conflicts are found.

You'll need to manually backup/remove conflicting directories first.

### Manual stowing (if skipped during installation)

```bash
# Stow system configuration
cd ~/dotfiles
sudo stow --target=/etc --dir=~/dotfiles/etc
```

### Udev Rules

Udev device rules are located in `etc/udev/rules.d/`.

**After making changes:**

```bash
# Edit files in ~/dotfiles/etc/udev/rules.d/
# Changes are automatically reflected in /etc/udev/ via symlinks

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Notes

- ⚠️ **Neovim config**: Clones my personal neovim configuration from
  umutondersu/nvim
- 🔄 **Shell change**: After installation, log out and log back in for Fish
  shell to become active
- 🐠 **Fish variables**: The install script automatically configures git to
  ignore local changes to `.config/fish/fish_variables`. This prevents hundreds
  of tide prompt cache lines from cluttering git status
  while keeping the baseline Tide configuration in the repo for new clones.
  Use `fish_variables_git` to toggle this behavior

## Desktop Environment

For restoring the entire desktop environment (Icons, Themes, Fonts, Background,
Extensions, etc) you can use your own configuration.

### Gnome

[SaveDesktop](https://flathub.org/apps/io.github.vikdevelop.SaveDesktop)

### KDE

[Konsave](https://github.com/Prayag2/konsave)
