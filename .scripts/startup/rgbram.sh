#!/bin/bash
#
# Kingston Fury Beast DDR5 RGB controller script
#
# Sauce:
# https://gitlab.com/CalcProgrammer1/OpenRGB/-/issues/2879#note_1336953263
#
# Supports only static colors.
#
# Usage examples:
#
# sudo ./rgbram.sh ff 00 00 # red
# sudo ./rgbram.sh 00 ff ff # cyan
# sudo ./rgbram.sh 00 00 00 # lights out

if ! i2cdetect -l | grep -q I801; then
  echo "Intel I801 not detected! use sudo apt install i2c-tools"
  exit 2
fi

# from 0 to 0x63
brightness=0x2

ramstick1=0x61
ramstick2=0x63

i2cbus=$(i2cdetect -l | grep I801 | awk '{ print $1 }' | sed 's/i2c-//')
i2cbusdet=$(i2cdetect -l | grep I801)

if ! [[ $1 =~ ^[0-9a-fA-F]{2}$ ]]; then
  echo "$1 is not a valid octet hex value"
  exit 1
fi
red=$1

if ! [[ $2 =~ ^[0-9a-fA-F]{2}$ ]]; then
  echo "$2 is not a valid octet hex value"
  exit 1
fi
green=$2

if ! [[ $3 =~ ^[0-9a-fA-F]{2}$ ]]; then
  echo "$3 is not a valid octet hex value"
  exit 1
fi
blue=$3

echo "Detected bus: $i2cbusdet"
echo -e "Setting up color value of #$red$green$blue\n"

# ram stick 1

i2cset -y "$i2cbus" "$ramstick1" 0x08 0x53
sleep 0.020
i2cset -y "$i2cbus" "$ramstick1" 0x09 0x00
sleep 0.020
i2cset -y "$i2cbus" "$ramstick1" 0x31 0x"$red"
sleep 0.020
i2cset -y "$i2cbus" "$ramstick1" 0x32 0x"$green"
sleep 0.020
i2cset -y "$i2cbus" "$ramstick1" 0x33 0x"$blue"
sleep 0.020
i2cset -y "$i2cbus" "$ramstick1" 0x20 "$brightness"
sleep 0.020
i2cset -y "$i2cbus" "$ramstick1" 0x08 0x44

# ram stick 2

i2cset -y "$i2cbus" "$ramstick2" 0x08 0x53
sleep 0.020
i2cset -y "$i2cbus" "$ramstick2" 0x09 0x00
sleep 0.020
i2cset -y "$i2cbus" "$ramstick2" 0x31 0x"$red"
sleep 0.020
i2cset -y "$i2cbus" "$ramstick2" 0x32 0x"$green"
sleep 0.020
i2cset -y "$i2cbus" "$ramstick2" 0x33 0x"$blue"
sleep 0.020
i2cset -y "$i2cbus" "$ramstick2" 0x20 "$brightness"
sleep 0.020
i2cset -y "$i2cbus" "$ramstick2" 0x08 0x44
