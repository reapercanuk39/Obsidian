#!/bin/bash
set -e

WALLPAPER_DIR="rootfs/usr/share/backgrounds/obsidian"
mkdir -p "$WALLPAPER_DIR"

echo "=== Generating Forge-Themed Wallpapers ==="

# Use ImageMagick to create abstract forge-themed wallpapers
# Colors: deep blacks (#0a0a0a), ember orange (#FF7A1A), molten red (#CC0000), steel gray (#4a4a4a)

# Wallpaper 1: Molten Flow
convert -size 1920x1080 gradient:'#0a0a0a-#1a0a0a' \
  \( +clone -sparse-color barycentric '0,0 black 1920,1080 #FF7A1A' -modulate 100,150 \) \
  -compose screen -composite \
  -blur 0x50 \
  "$WALLPAPER_DIR/01-molten-flow.jpg"

# Wallpaper 2: Ember Glow
convert -size 1920x1080 plasma:fractal \
  -colorspace RGB -auto-level \
  -fill '#0a0a0a' -colorize 70% \
  \( +clone -fill '#FF7A1A' -colorize 30% \) -compose lighten -composite \
  -blur 0x30 \
  "$WALLPAPER_DIR/02-ember-glow.jpg"

# Wallpaper 3: Steel Forge (dark with orange accents)
convert -size 1920x1080 xc:'#0a0a0a' \
  \( +clone -sparse-color barycentric '960,540 #FF7A1A 0,0 #0a0a0a 1920,0 #0a0a0a 0,1080 #0a0a0a 1920,1080 #0a0a0a' \) \
  -compose screen -composite -blur 0x80 \
  "$WALLPAPER_DIR/03-steel-forge.jpg"

# Wallpaper 4: Obsidian Depths
convert -size 1920x1080 gradient:'#000000-#2a1a0a' \
  \( +clone -swirl 60 \) -compose multiply -composite \
  -modulate 80,120 \
  "$WALLPAPER_DIR/04-obsidian-depths.jpg"

# Wallpaper 5: Forge Fire
convert -size 1920x1080 plasma:fractal \
  -blur 0x20 \
  \( +clone -colorspace HSL -separate -delete 1,2 \
     -level 0,50% -colorspace RGB \
     \( +clone -fill '#CC0000' -colorize 100% \) -compose multiply -composite \
     \( +clone -fill '#FF7A1A' -colorize 50% \) -compose lighten -composite \
  \) -compose lighten -composite \
  -background '#0a0a0a' -flatten \
  "$WALLPAPER_DIR/05-forge-fire.jpg"

# Wallpaper 6: Minimal Dark (solid with subtle gradient)
convert -size 1920x1080 gradient:'#0a0a0a-#1a1a1a' \
  -blur 0x100 \
  "$WALLPAPER_DIR/06-minimal-dark.jpg"

# Wallpaper 7: Molten Steel
convert -size 1920x1080 gradient:'#4a4a4a-#0a0a0a' \
  \( +clone -sparse-color barycentric '0,540 #FF7A1A 1920,540 #4a4a4a' \) \
  -compose screen -composite -blur 0x60 \
  "$WALLPAPER_DIR/07-molten-steel.jpg"

# Wallpaper 8: Abstract Forge (geometric with embers)
convert -size 1920x1080 xc:'#0a0a0a' \
  -fill '#FF7A1A' -draw 'circle 400,300 400,400' -blur 0x80 \
  -fill '#CC0000' -draw 'circle 1400,700 1400,800' -blur 0x80 \
  -fill '#4a4a4a' -draw 'circle 960,540 960,640' -blur 0x60 \
  -modulate 100,150 \
  "$WALLPAPER_DIR/08-abstract-forge.jpg"

echo "Generated 8 wallpapers in $WALLPAPER_DIR"
ls -lh "$WALLPAPER_DIR"

echo "=== Wallpaper generation complete ==="
