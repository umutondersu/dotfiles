# My Dotfiles for Ubuntu WSL

This Repository contains my configuration files on my WSL Ubuntu system

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
- [Zoxide](https://github.com/nanotee/zoxide.vim)
- [Synth-shell](https://github.com/andresgongora/synth-shell) (Optinal since fish is used)

## Installation

```
$ mkdir ~/dotfiles
$ cd ~/dotfiles
$ git clone https://github.com/umutondersu/dotfiles_ubuntu.git
$ stow .
```

After the the symlinks are created run the setup script

```
$ cd ~
$ chmod +x setup/setup.sh
$ cd setup
$ ./setup.sh
```

## Notes

- Since this an wsl I have created a symlink for the neovim configuration from Windows 10. You can find it in my windows 10 config repository.
