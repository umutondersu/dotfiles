# Docker Testing Scripts

This directory (`setup/.test/`) contains scripts to test the development environment installation in a clean Ubuntu 22.04 Docker container.

## Location

All test scripts are located in `setup/.test/` directory:
- `test-in-docker-automated.sh` - Automated testing
- `test-in-docker-manual.sh` - Manual/interactive testing
- `verify-installation.sh` - Standalone verification script
- `TESTING.md` - This documentation

## Available Scripts

### 1. `test-in-docker-automated.sh` (Recommended)
Fully automated test that runs installation and verification automatically.

**Usage (from dotfiles root):**
```bash
./setup/.test/test-in-docker-automated.sh
```

**What it does:**
1. Starts an Ubuntu 22.04 container
2. Installs prerequisites (git, curl, sudo)
3. Copies dotfiles into the container
4. Runs `install.sh` (dev environment mode)
5. Runs `verify-installation.sh`
6. Reports test results
7. Exits with appropriate status code (0 = success, 1 = failure)

**Use this for:**
- Quick validation before committing changes
- CI/CD pipelines
- Regression testing

### 2. `test-in-docker-manual.sh`
Interactive test where you manually run installation steps.

**Usage (from dotfiles root):**
```bash
./setup/.test/test-in-docker-manual.sh
```

**What it does:**
1. Starts an Ubuntu 22.04 container with dotfiles mounted
2. Drops you into a bash shell
3. You manually run the installation steps
4. Allows interactive debugging and exploration

**Use this for:**
- Debugging installation issues
- Testing changes interactively
- Exploring the installed environment

**Manual steps inside container:**
```bash
apt-get update && apt-get install -y git curl sudo
cp -r /dotfiles /root/dotfiles
cd /root/dotfiles
./install.sh  # Runs dev environment mode by default
./setup/.test/verify-installation.sh  # Optional: verify installation
exec fish                              # Test Fish shell
```

### 3. `verify-installation.sh`
Standalone verification script that checks the installation.

**Usage (from dotfiles root):**
```bash
./setup/.test/verify-installation.sh
```

**What it tests:**
- ✓ Fish shell is installed and starts without errors
- ✓ Devbox is installed
- ✓ Devbox PATH is correctly set in Fish
- ✓ Devbox packages are accessible in Fish
- ✓ Configuration files exist and are properly symlinked
- ✓ SHELL variable is set to fish
- ✓ No common Fish startup errors (Missing end, Unknown command, etc.)

**Exit codes:**
- `0` = All tests passed
- `1` = Some tests failed

## Test Coverage

The automated tests verify:

### PATH Integration
- Devbox packages directory is in Fish's PATH
- `$DEVBOX_PACKAGES_DIR` environment variable is set
- Sample packages (fzf, nvim, lazygit, rg, bat) are accessible

### Fish Shell Integration
- Fish starts without syntax errors
- No "Missing end to balance this if statement" errors
- No "Unknown command" errors
- SHELL variable is set to fish in Fish environment

### Configuration Files
- Fish config directory exists (`~/.config/fish`)
- Devbox Fish integration file exists (`~/.config/fish/conf.d/devbox.fish`)
- Neovim config directory exists (if applicable)
- Stow symlinks are created correctly

## Troubleshooting

### Tests fail with "Missing end" error
This means the devbox Fish integration is generating bash syntax instead of Fish syntax.
- **Fix**: Ensure `.config/fish/conf.d/devbox.fish` contains `set -gx SHELL fish` before calling devbox

### Tests fail with "Unknown command: fzf"
This means devbox packages aren't in the PATH when Fish starts.
- **Fix**: Ensure devbox PATH is set before other Fish plugins try to use devbox tools

### Container fails to start
- Check Docker is running: `docker ps`
- Check Docker has permissions: `docker run hello-world`
- Check disk space: `df -h`

## CI/CD Integration

For use in CI/CD pipelines:

```bash
#!/bin/bash
set -e

# Run automated tests (from dotfiles root)
./setup/.test/test-in-docker-automated.sh

# Exit with test result code
exit $?
```

## Requirements

- Docker installed and running
- Sufficient disk space (~2GB for container + packages)
- Internet connection (for downloading packages)

## Notes

- Tests run in an ephemeral container (automatically removed after completion)
- Dotfiles are mounted read-only to prevent accidental modifications
- Each test run starts from a clean Ubuntu 22.04 base image
