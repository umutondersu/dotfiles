# My Dotfiles for Pop!\_OS Desktop

This Repository contains my Pop!\_OS configuration files symlinked with stow. Should be able to work the same in any Ubuntu or Debian Based Linux Distro that has apt

## Requirements

- Git

```bash
sudo apt install git
```

- Tmux

```bash
sudo apt install tmux
```

All other requriements will be installed with the install script

## Installation

### Development Environment

Just run the install script in your home directory after cloning the repository

```bash
$ cd
$ git clone https://github.com/umutondersu/dotfiles.git
$ ./dotfiles/install.sh
```

⚠️ This will also clone my neovim configuration inside `~/.config/nvim`

### Gnome Desktop Environment

![Screenshot from 2024-11-01 14-38-56](https://github.com/user-attachments/assets/6fcd937b-5756-43f5-9664-c30c9749169c)

Themes have to be in the `~/.themes` and Icons have to be in the `~/.icons` directory

- Themes: [Dracula](https://github.com/dracula/gtk/archive/refs/heads/master.zip), [Sweet Dark](https://www.gnome-look.org/p/1253385)

- Icons: [Flatery Indigo Dark](https://www.gnome-look.org/p/1332404)

- Wallpaper: [eberhardgross](https://unsplash.com/photos/a-bird-flying-through-a-cloudy-blue-sky-xC7Ho08RYF4)

for restoring the entire desktop enviroment (Icons, Themes, Fonts, Background and flatpak apps) you can use your own configuration with [SaveDesktop](https://flathub.org/apps/io.github.vikdevelop.SaveDesktop) or by using the `gnome/.settings.rc` config with dconf by using `dconf load / < ~/dotfiles/gnome/.settings.rc`

### All other stuff

TODO

## Notes

If you are going to use the dotfiles inside a devcontainer with neovim, you must add the following lines below to your `devcontainer/.devcontainer.json` for the clipboards to be synced

```json
  "runArgs": [
    "--env",
    "DISPLAY",
    "--env",
    "XAUTHORITY=/tmp/.docker.xauth",
    "--volume",
    "/tmp/.X11-unix:/tmp/.X11-unix",
    "--volume",
    "${localEnv:HOME}/.Xauthority:/tmp/.docker.xauth"
  ]
```
