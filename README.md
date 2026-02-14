# My Dotfiles for Pop!\_OS Desktop (Devbox-based)

This repository contains my Linux configuration files managed with [Devbox](https://www.jetify.com/devbox) for distro-agnostic package management and [GNU Stow](https://www.gnu.org/software/stow/) for dotfile symlinking.

## ✨ Devbox-based Installation

The installation process uses Devbox as a global package manager. This makes the setup:

- **Distro-agnostic(mostly)**: Works on any Linux distribution (Ubuntu, Debian, Fedora, Arch, NixOS, etc.)
- **Reproducible**: Same package versions across all machines via `devbox.json`
- **Isolated**: Doesn't interfere with system package manager
- **Simple**: One command to install everything

## Requirements

- **Git**
- **curl**

That's it! The install script handles everything else, including devbox installation.

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

### Prerequisites (Installed First)

- **fish**: Shell (installed via distro package manager before devbox)
  - Ubuntu/Pop!_OS: PPA `ppa:fish-shell/release-4`
  - Debian: OpenSUSE Build Service repository

### Core Development Tools (21 packages - in both installations)

**Shell & CLI Tools:**

- stow, fzf, ripgrep, fd, zoxide, bat, lsd, thefuck, tldr, fish-lsp, direnv

**Development:**

- neovim, go, nodejs_22, python312, deno

**Utilities:**

- dysk (disk usage)
- superfile (file manager)
- curlie (HTTP client)
- posting (API client)
- vegeta (load testing)
- lazygit (git client)
- lazydocker (docker client)

### Desktop-Only Additions (3 packages - only in `./install.sh`)

- **tmux**: Terminal multiplexer
- **streamrip**: Media downloader
- **yt-dlp**: Video downloader

### Manual Installations (Both installations)

- **fish**: Shell (script in `setup/fish.sh`) - installed before devbox

### Manual Installations (Desktop only)

- **kitty**: Terminal emulator (script in `setup/kitty.sh`)
- **nerd-dictation**: Voice input (script in `setup/nerd-dictation.sh`)
- **vosk**: Speech recognition library (script in `setup/vosk-install.sh`)
- **TPM**: Tmux Plugin Manager (git clone to `~/.tmux/plugins/tpm`)

See `.local/share/devbox/global/default/devbox.json` for the core package configuration.

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

Package configuration is stored in `.local/share/devbox/global/default/devbox.json` and is automatically synced via stow.

## Shell Integration

Fish shell is automatically configured to load devbox global packages via `.config/fish/conf.d/devbox.fish`.

When you start a new Fish shell, all devbox packages are immediately available.

## Notes

- ⚠️ **Neovim config**: Clones my personal neovim configuration from umutondersu/nvim
- 🔄 **Shell change**: After installation, log out and log back in for Fish shell to become active
- 📌 **Version pinning**: Core packages are pinned to specific versions. Desktop: tmux pinned, streamrip/yt-dlp use @latest
- 🔌 **nvm.fish**: You have nvm.fish plugin installed. Since devbox provides nodejs_22, nvm is optional but won't conflict

### Gnome Desktop Environment

![Screenshot from 2024-11-01 14-38-56](https://github.com/user-attachments/assets/6fcd937b-5756-43f5-9664-c30c9749169c)

Themes have to be in the `~/.themes` and Icons have to be in the `~/.icons` directory

- Themes: [Dracula](https://github.com/dracula/gtk/archive/refs/heads/master.zip), [Sweet Dark](https://www.gnome-look.org/p/1253385)

- Icons: [Flatery Indigo Dark](https://www.gnome-look.org/p/1332404)

- Wallpaper: [eberhardgross](https://unsplash.com/photos/a-bird-flying-through-a-cloudy-blue-sky-xC7Ho08RYF4)

For restoring the entire desktop environment (Icons, Themes, Fonts, Background, Extensions, Desktop and Flatpak apps) you can use your own configuration with [SaveDesktop](https://flathub.org/apps/io.github.vikdevelop.SaveDesktop) or by using the `gnome/.settings.rc` config with dconf by using `dconf load / < ~/dotfiles/gnome/.settings.rc` I keep my SaveDesktop backup on cloud due to its size
