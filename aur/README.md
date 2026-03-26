# AUR Packages Backup & Restore

This README shows how to export your manually installed AUR packages and reinstall them on a new machine using `paru`.

## Export installed AUR packages
# List all manually installed AUR packages
paru -Qm > aur-packages.txt

## Install AUR packages on a new machine
# Install packages from the list, skipping already installed ones
paru -S --needed - < aur-packages.txt

## Optional: Backup all explicitly installed packages (Pacman + AUR)
# Backup all explicitly installed packages (including official repos)
pacman -Qqe > pkglist.txt