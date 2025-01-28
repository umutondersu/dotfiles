#!/bin/bash

# Fetch the latest release tag from GitHub
OWNER="tsenart"
REPO="vegeta"
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest")
LATEST_TAG=$(echo "$LATEST_RELEASE" | jq -r .tag_name)

# Construct the URL for the Linux AMD64 executable
DOWNLOAD_URL="https://github.com/$OWNER/$REPO/releases/download/$LATEST_TAG/vegeta_${LATEST_TAG#v}_linux_amd64.tar.gz"

# Download the tarball
curl -L -o vegeta.tar.gz "$DOWNLOAD_URL"

# Extract the tarball
tar -xzf vegeta.tar.gz

# Move the executable to /usr/local/bin
sudo mv vegeta /usr/local/bin

# Clean up
rm vegeta.tar.gz
