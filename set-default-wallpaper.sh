#!/bin/bash
set -e

echo "=== Setting Default Wallpaper ==="

# Set default wallpaper in XFCE config
WALLPAPER_PATH="/usr/share/backgrounds/obsidian/01-molten-flow.jpg"
XFCE_CONFIG="rootfs/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"

if [ -f "$XFCE_CONFIG" ]; then
    # Update the wallpaper path in XFCE config
    sed -i "s|<property name=\"last-image\" type=\"string\" value=\".*\"/>|<property name=\"last-image\" type=\"string\" value=\"$WALLPAPER_PATH\"/>|g" "$XFCE_CONFIG"
    echo "Updated XFCE default wallpaper to: $WALLPAPER_PATH"
else
    echo "XFCE config not found, skipping..."
fi

echo "=== Default wallpaper set ==="
