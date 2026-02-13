#!/bin/bash
set -e

echo "🎤 Installing nerd-dictation..."

INSTALL_DIR="$HOME/.config/nerd-dictation"
VOSK_MODEL="vosk-model-small-en-us-0.15"

# Clone nerd-dictation if not exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Cloning nerd-dictation..."
    git clone https://github.com/ideasman42/nerd-dictation.git "$INSTALL_DIR"
else
    echo "✅ nerd-dictation already cloned, skipping..."
fi

# Download vosk model
cd "$INSTALL_DIR"
if [ ! -d "$VOSK_MODEL" ]; then
    echo "Downloading vosk model..."
    wget "https://alphacephei.com/vosk/models/${VOSK_MODEL}.zip"
    unzip "${VOSK_MODEL}.zip"
    rm "${VOSK_MODEL}.zip"
else
    echo "✅ Vosk model already downloaded, skipping..."
fi

echo "✅ nerd-dictation setup complete"
