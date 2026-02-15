#!/bin/bash 
# WARN: Depreciated, use NormCap

# Dependencies: tesseract-ocr imagemagick scrot xsel gnome-screenshot libnotify-bin
REQUIRED_PACKAGES=("tesseract-ocr" "imagemagick" "scrot" "xsel" "gnome-screenshot" "libnotify-bin")
MISSING_PACKAGES=()

for PKG in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -s "$PKG" &> /dev/null; then
        echo "Missing package: $PKG"
        MISSING_PACKAGES+=("$PKG")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "The following packages are missing: ${MISSING_PACKAGES[*]}"
    echo "Attempting to install them now. This may require sudo privileges."
    
    # Attempt to update and install
    if sudo apt-get update && sudo apt-get install -y "${MISSING_PACKAGES[@]}"; then
        echo "All missing packages installed successfully."
    else
        echo "Failed to install some or all missing packages."
        echo "Please try installing them manually: sudo apt-get install -y ${MISSING_PACKAGES[*]}"
        exit 1
    fi
fi

#tesseract_lang=eng+ita
LANG=eng+spa+tur
# quick language menu, add more if you need other languages.

SCR_IMG=`mktemp`
trap "rm $SCR_IMG*" EXIT

#grim -g "$(slurp)" -q 100 -l 1 $SCR_IMG.png
#scrot -s -f $SCR_IMG.png -q 100
gnome-screenshot -a -f "$SCR_IMG".png
# increase image quality with option -q from default 75 to 100

mogrify -modulate 100,0 -resize 400% "$SCR_IMG".png

#should increase detection rate

#tesseract $SCR_IMG.png $SCR_IMG &> /dev/null
tesseract "$SCR_IMG".png "$SCR_IMG" -l "$LANG" &> /dev/null

cat "$SCR_IMG".txt | xsel -bi

notify-send --app-name "Text copier" --icon "/home/chromiell/Documents/Scripts/TextGrabber.png" "Text copied from the screen" "Now you can paste it wherever you like"

exit
