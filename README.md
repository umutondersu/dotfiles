# My Dotfiles for Pop!\_OS Desktop

This repository contains my Linux configuration files managed with
[GNU Stow](https://www.gnu.org/software/stow/) for dotfile symlinking.

- **Distro-agnostic**: Works on any Linux distribution with [Devbox](https://www.jetify.com/devbox)
- **Reproducible**: Same package versions across all machines via `devbox.json`
- **Isolated**: Doesn't interfere with system package manager
- **Simple**: One command to install everything

## Requirements

- **git**
- **curl**
- **sudo**

The install script should handle everything else (check [Prerequisites](#prerequisites))

## Installation

This repository offers two installation modes depending on your environment:

### 1. Desktop Installation (Full Setup)

For workstations and desktop environments with GUI applications:

```bash
cd ~
git clone https://github.com/umutondersu/dotfiles.git
cd dotfiles
./install.sh
```

### 2. DevPod/Remote Installation (Minimal Setup)

For SSH sessions, remote environments, containers, and DevPods:

```bash
cd ~
git clone https://github.com/umutondersu/dotfiles.git
cd dotfiles
./devpod-install.sh
```

## What Gets Installed

### Prerequisites

**These are only installed with the script if you have apt. Otherwise, get
them before installation**

- **fish 4.4.0**
  - Ubuntu/Pop!\_OS: PPA `ppa:fish-shell/release-4`
  - Debian: OpenSUSE Build Service repository

- **stow**

### Devbox Packages

#### Package Inventory Note

These might be old if i forgot to update readme after adding packages

**Shell & CLI Tools:**

- fzf, ripgrep, fd, zoxide, bat, lsd, thefuck, tldr, fish-lsp, direnv

**Development:**

- neovim, go, nodejs_22, python312, deno

**Utilities:**

- curlie (HTTP client)
- posting (API client)
- vegeta (load testing)
- lazygit (git client)
- lazydocker (docker client)
- jq (JSON Processor)

### Desktop-Only Packages (only in `./install.sh`)

- **tmux**: Terminal multiplexer
- **streamrip**: Media downloader
- **yt-dlp**: Video downloader
- **dysk**: Disk usage analyzer (also in base config)

#### Manual Installations with scripts

- **kitty**: Terminal emulator (script in `setup/kitty.sh`)
- **nerd-dictation**: Voice input (script in `setup/nerd-dictation.sh`)
- **vosk**: Speech recognition library (script in `setup/vosk-install.sh`)
- **TPM**: Tmux Plugin Manager (git clone to `~/.tmux/plugins/tpm`)

See `.devbox/devbox.json` for the core package template.

## Devbox Configuration Approach

The devbox configuration uses a **template-based approach** rather than direct symlinking:

- **Template Location**: `.devbox/devbox.json` (tracked in git)
- **Working Location**: `~/.local/share/devbox/global/default/devbox.json`
  (copied during installation)

### Why Copy Instead of Stow (Symlink)?

1. **Desktop-specific packages**: `install.sh` adds extra packages using
   `devbox global add` which creates a permanent dirty git with stow
2. **Environment flexibility**: DevPod environments get the base config,
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

**Permanent changes must be synced with `sync-devbox`. This fish functions sync
the packages from the working location to the repository. Excluding the desktop
only packages**

## Testing

Automated Docker tests are available to verify the installation in a clean environment:

See [`setup/.test/TESTING.md`](setup/.test/TESTING.md) for detailed documentation.

## Notes

- ⚠️ **Neovim config**: Clones my personal neovim configuration from
  umutondersu/nvim
- 🔄 **Shell change**: After installation, log out and log back in for Fish
  shell to become active
- 🐠 **Fish variables**: The install script automatically configures git to
  ignore local changes to `.config/fish/fish_variables` (Tide prompt cache)
  using `git update-index --assume-unchanged`. This prevents hundreds of cache
  lines from cluttering git status while keeping the baseline Tide configuration
  in the repo for new clones. Use `fzf_variables_git` to unlock/lock this
  behavior

## Gnome Desktop Environment

![Screenshot from 2024-11-01 14-38-56](https://github.com/user-attachments/assets/6fcd937b-5756-43f5-9664-c30c9749169c)

Themes have to be in the `~/.themes` and Icons have to be in the `~/.icons` directory

- Themes: [Dracula](https://github.com/dracula/gtk/archive/refs/heads/master.zip),
  [Sweet Dark](https://www.gnome-look.org/p/1253385)

- Icons: [Flatery Indigo Dark](https://www.gnome-look.org/p/1332404)

- Wallpaper: [eberhardgross](https://unsplash.com/photos/a-bird-flying-through-a-cloudy-blue-sky-xC7Ho08RYF4)

For restoring the entire desktop environment (Icons, Themes, Fonts, Background,
Extensions, Desktop and Flatpak apps) you can use your own configuration with
[SaveDesktop](https://flathub.org/apps/io.github.vikdevelop.SaveDesktop) or by
using the `gnome/.settings.rc` config with dconf by using
`dconf load / < ~/dotfiles/gnome/.settings.rc` I keep my SaveDesktop backup on
cloud due to its size
