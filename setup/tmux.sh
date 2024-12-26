#!/bin/bash

TPM_DIR=~/.tmux/plugins/tpm

# Check if TPM directory exists if not clone it
if [ ! -d "$TPM_DIR" ]; then
    echo "Cloning tmux-plugins/tpm into $TPM_DIR..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "Clone completed successfully."
fi

echo "To install plugins, follow these steps:"
echo "1. Start tmux by typing 'tmux' in your terminal."
echo "2. Press <Ctrl-Space> + I to fetch and install plugins using TPM."
echo "3. Restart tmux to source the updated configuration."
