# My Dotfiles for Pop!\_OS Desktop

This Repository contains my Pop!\_OS sconfiguration files. Should be able to work the same in any Ubuntu Based Linux Distro

## Requirements

- Stow

```
sudo apt install stow
```

- Git

```
sudo apt install git
```

- Tmux

```
sudo apt install tmux
```

- [Fish Shell](https://www.jwillikers.com/switch-to-fish)
- [Zoxide](https://github.com/ajeetdsouza/zoxide)
- [Synth-shell](https://github.com/andresgongora/synth-shell) (Optinal since fish is used)

## Installation

```
$ git clone https://github.com/umutondersu/dotfiles_ubuntu.git dotfiles
$ cd ~/dotfiles
$ stow --adopt .
$ git restore .
```

After the the symlinks are created run the setup script

```
$ cd ~
$ chmod +x ~/dotfiles/setup/tmux_setup.sh
$ ~/dotfiles/setup/tmux_setup.sh
```

## Gnome

Themes have to be in the `~/.themes` and Icons have to be in the `~/.icons` directory

- Themes: [Dracula](https://github.com/dracula/gtk/archive/refs/heads/master.zip), [Sweet Dark](https://www.gnome-look.org/p/1253385)

- Icons: [Flatery Indigo Dark](https://www.gnome-look.org/p/1332404)

for restoring the entire desktop enviroment (Icons, Themes, Fonts, Background and flatpak apps) you can use your own configuration with [SaveDesktop](https://flathub.org/apps/io.github.vikdevelop.SaveDesktop) or by using the `gnome/.settings.rc` config with dconf by using `dconf load / < ~/dotfiles/gnome/.settings.rc`

## Notes
