# AUR Packages Backup & Restore

## 1. Add the Extra Repositories

```bash
sudo tee -a /etc/pacman.conf < ~/dotfiles/aur/extra-repos.conf
sudo pacman -Sy
```

## 2. Install AUR packages on a new machine

```bash
paru -S --needed - < ~/dotfiles/aur/aur-packages.txt
```

### Export manually installed AUR packages

```bash
~/dotfiles/aur/get-aur-packages.sh > ~/dotfiles/aur/aur-packages.txt
```

This script includes packages with Packager: Unknown attribute,
ensuring all AUR/foreign packages are included.
