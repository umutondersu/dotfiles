#!/bin/bash

./setup/stow.sh
./setup/binaries.sh
./setup/wo_cargo.sh
./setup/fish.sh

git clone https://github.com/umutondersu/nvim.git ~/.config/nvim
sudo chsh -s /usr/bin/fish $USER

if [ "$DEVCONTAINER" = "true" ] || [ "$CODESPACES" = "true" ] || [ "$REMOTE_CONTAINERS" = "true" ]; then
		mkdir -p ~/.gnupg
		echo "use-standard-socket" > ~/.gnupg/gpg-agent.conf
else
	./setup/tmux_setup.sh
fi
