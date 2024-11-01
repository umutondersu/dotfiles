#!/bin/bash

wget -O /tmp/bat-musl_0.24.0_amd64.deb https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-musl_0.24.0_amd64.deb && sudo dpkg -i /tmp/bat-musl_0.24.0_amd64.deb && rm /tmp/bat-musl_0.24.0_amd64.deb
