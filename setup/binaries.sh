#!/bin/bash

for script in ./setup/binaries/*.sh; do
  bash "$script"
done

