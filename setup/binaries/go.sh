#!/bin/bash
set -e

# Detect latest Go version
LATEST=$(wget -qO- --no-check-certificate https://go.dev/VERSION?m=text | head -n1 | awk '{print $1}')

# Download and extract
wget "https://go.dev/dl/${LATEST}.linux-amd64.tar.gz" -O /tmp/go.tar.gz

sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz
