#!/bin/bash

TPM_DIR=~/.tmux/plugins/tpm

# Check if TPM directory exists
if [ ! -d "$TPM_DIR" ]; then
    echo "Cloning tmux-plugins/tpm into $TPM_DIR..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "Clone completed successfully."

    echo "To install plugins, follow these steps:"
    echo "1. Start tmux by typing 'tmux' in your terminal."
    echo "2. Press <Ctrl-Space> + I to fetch and install plugins using TPM."
    echo "3. Restart tmux to source the updated configuration."

else
    echo "TPM directory already exists. No need to clone."

     if [ -d "~/.config/tmux/plugins" ]; then
        echo "To install plugins, follow these steps:"
        echo "1. Start tmux by typing 'tmux' in your terminal."
        echo "2. Press <Ctrl-Space> + I to fetch and install plugins using TPM."
        echo "3. Restart tmux to source the updated configuration."
    fi
fi
