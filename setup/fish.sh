#!/bin/bash

sudo apt update
sudo apt install -y software-properties-common
sudo apt-add-repository -y ppa:fish-shell/release-4
sudo apt update
sudo apt install -y fish

fish -c 'nvm install $nvm_default_version'
