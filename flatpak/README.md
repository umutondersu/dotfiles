# Flatpak Apps

## Restore

Install all apps from the list:

```sh
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
xargs -a flatpak-apps.txt flatpak install -y
```

## Backup

Save currently installed user apps to the list:

```sh
flatpak list --app --columns=application > ~/dotfiles/flatpak/flatpak-apps.txt
```
