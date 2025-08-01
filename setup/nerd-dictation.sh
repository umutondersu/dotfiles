#!/bin/bash

pip3 install vosk
git clone https://github.com/ideasman42/nerd-dictation.git $HOME/.config/nerd-dictation
cd $HOME/.config/nerd-dictation
wget https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip
unzip vosk-model-small-en-us-0.15.zip
mv vosk-model-small-en-us-0.15 model
rm vosk-model-small-en-us-0.15.zip
