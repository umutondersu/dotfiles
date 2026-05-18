# AUR Packages Backup & Restore

## 1. Add the Extra Repositories

```bash
sudo tee -a /etc/pacman.conf < ~/dotfiles/aur/extra-repos.conf
sudo pacman -Sy
```

## 2. Install AUR packages on a new machine

```bash
paru -S --needed --noconfirm - < ./dotfiles/aur/aur-packages.txt
```

## Export manually installed AUR packages

```bash
pacman -Qqe | pacman -Qi - | awk '/^Name/ {name=$3} /^Packager/ && $3=="Unknown" {print name}' > ~/dotfiles/aur/aur-packages.txt
```

This script includes packages with Packager: Unknown attribute,
ensuring all AUR/foreign packages are included.

It's an example script. You can manually add/remove package names from the file
