#!/bin/bash

wget -O /tmp/lsd-musl_1.1.5_amd64.deb https://github.com/lsd-rs/lsd/releases/download/v1.1.5/lsd-musl_1.1.5_amd64.deb && sudo dpkg -i /tmp/lsd-musl_1.1.5_amd64.deb && rm /tmp/lsd-musl_1.1.5_amd64.deb
