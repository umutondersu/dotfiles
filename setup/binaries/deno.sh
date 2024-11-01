#!/bin/bash

curl -fsSL https://deno.land/install.sh | sh -s -- -y
export PATH=$HOME/.deno/bin/deno:$PATH
