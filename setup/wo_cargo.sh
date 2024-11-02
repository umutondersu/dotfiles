#!/bin/bash

for script in ./setup/wo_cargo/*.sh; do
  bash "$script"
done
