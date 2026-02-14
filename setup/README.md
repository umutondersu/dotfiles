# Devbox-based Installation

This directory contains installation scripts that support two installation modes:

1. **Desktop Installation** (`./install.sh`) - Full setup with GUI apps and tmux
2. **DevPod/Remote Installation** (`./devpod-install.sh`) - Minimal setup for SSH/containers

## How It Works

1. **devbox.json is in the repo**: Located at `.local/share/devbox/global/default/devbox.json`
2. **Stow symlinks it**: When you run `stow . --adopt`, it creates a symlink to `~/.local/share/devbox/global/default/devbox.json`
3. **Devbox reads it**: After symlinking, `devbox global install` installs all packages
4. **Git tracks it**: Your package list is version controlled in the dotfiles repo

## Quick Start

### Desktop Installation

From the dotfiles directory:

```bash
./install.sh
```

### DevPod/Remote Installation

From the dotfiles directory:

```bash
./devpod-install.sh
```

## Installation Flows

### Desktop Installation Flow

```
install.sh
├── 1/8: setup/fish.sh              → Install Fish shell via distro package manager
├── 2/8: Auto-install devbox        → Install devbox (if needed)
├── 3/8: apt install stow           → Ensure stow is available
├── 4/8: stow . --adopt             → Symlink devbox.json + all dotfiles
├── 5/8: devbox global install      → Install 21 core packages from devbox.json
├── 6/8: devbox global add          → Add 4 desktop packages (tmux, streamrip, yt-dlp, dysk)
├── 7/8: setup/kitty.sh             → Curl installer + update-alternatives
├── 8/8: setup/nerd-dictation.sh    → Git clone + pip install vosk
└── Post: setup/common.sh           → Neovim clone + TPM install + chsh to fish
```

### DevPod/Remote Installation Flow

```
devpod-install.sh
├── 1/6: setup/fish.sh              → Install Fish shell via distro package manager
├── 2/6: Auto-install devbox        → Install devbox (if needed)
├── 3/6: apt install stow           → Ensure stow is available
├── 4/6: stow . --adopt             → Symlink devbox.json + all dotfiles
├── 5/6: devbox global install      → Install 21 core packages from devbox.json
└── 6/6: setup/common.sh            → Neovim clone + chsh to fish
                                      (NO tmux, NO TPM, NO desktop apps)
```

## Package Management

### Adding Packages

```bash
# Via command line (recommended)
devbox global add <package-name>

# Or manually edit
vim ~/.local/share/devbox/global/default/devbox.json
# Then run
devbox global install
```

The symlink means changes are automatically tracked in git!

### Removing Packages

```bash
devbox global rm <package-name>
```

### Updating Packages

```bash
devbox global update
```

### Viewing Packages

```bash
devbox global list
```

## Managed Packages

### Core Packages (21) - In devbox.json

Used by **both** installation modes:

**Shell & Terminal:**
- stow, fzf

**Search & Navigation:**
- ripgrep, fd, zoxide

**File Utilities:**
- bat, lsd, superfile

**Development Tools:**
- neovim, go, nodejs_22, python312, deno
- fish-lsp

**Version Control:**
- lazygit, lazydocker

**HTTP/API Tools:**
- curlie, posting, vegeta

**Shell Enhancements:**
- thefuck, tldr, direnv

### Desktop-Only Packages (4) - Added via `devbox global add`

Only installed by `./install.sh`:

- **tmux**: Terminal multiplexer
- **streamrip**: Media downloader
- **yt-dlp**: Video downloader
- **dysk**: Disk usage analyzer

### Manual Installations - Both Installations

Installed before devbox (via system package manager):

- **fish**: Shell (setup/fish.sh - uses PPA on Ubuntu/Pop!_OS, OBS repo on Debian)

### Manual Installations - Desktop Only

Not managed by devbox (installed via scripts in `setup/`):

- **kitty**: Terminal emulator (requires update-alternatives setup)
- **nerd-dictation**: Voice input (not available in nixpkgs - git clone)
- **vosk**: Python dependency for nerd-dictation (pip install)
- **tpm**: Tmux Plugin Manager (git clone to `~/.tmux/plugins/tpm`)

### DevPod-Only Additions

None - the DevPod installation uses only the 21 core packages from devbox.json.

## Benefits

✅ **Git tracked**: Package list is version controlled  
✅ **Synced across machines**: Clone repo, run install script, packages sync automatically  
✅ **Standard location**: Uses devbox's expected config location  
✅ **Simple workflow**: Stow handles symlinking, devbox handles packages  
✅ **Distro agnostic**: Works on any Linux distribution  
✅ **Reproducible**: Same versions across all environments  
✅ **Two modes**: Desktop (full) or DevPod/Remote (minimal)

## Installation Scripts

### `install.sh` - Desktop Installation
- Installs 24 total packages (21 core + 3 desktop)
- Sets up kitty terminal
- Installs nerd-dictation for voice input
- Sets up tmux with TPM
- Clones Neovim configuration
- Sets Fish as default shell
- Full desktop environment setup

### `devpod-install.sh` - DevPod/Remote Installation
- Installs 21 core packages only
- No tmux (not needed for SSH/remote)
- No desktop applications
- No media downloaders
- Clones Neovim configuration
- Sets Fish as default shell
- Optimized for containers and remote environments

### `common.sh` - Shared Functions
Contains shared functions used by both installation scripts:
- `setup_neovim_config()` - Clones Neovim configuration
- `setup_fish_shell()` - Sets Fish as default shell with resilient error handling
- `setup_tpm()` - Installs Tmux Plugin Manager (desktop only)

## Testing

### Docker Testing

Test the DevPod installation in a clean Ubuntu container:

```bash
./test-in-docker.sh
```

This runs `devpod-install.sh` in an isolated environment to verify the minimal installation.

## Notes

- **nvm.fish plugin**: You have `jorgebucaran/nvm.fish` in your Fish plugins (via fisher). Since we're using `nodejs_22` directly from devbox, nvm is no longer needed for Node version management, but it won't conflict if you keep it.

- **tmux plugin manager**: Only `tmuxPlugins.tpm` is installed. You may need to run tmux and press `prefix + I` to install tmux plugins listed in your `.tmux.conf`.

- **Version pinning**: Core packages (21) are pinned to specific versions. Desktop packages: tmux is pinned, streamrip and yt-dlp use @latest for frequent updates.
