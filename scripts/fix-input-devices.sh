#!/bin/bash
#
# Obsidian OS - Fix Input Device Support
# ======================================
# Ensures keyboard and mouse work at login screen
#
# This script:
# 1. Adds USB HID modules to initramfs
# 2. Installs/verifies libinput driver
# 3. Rebuilds initramfs with input support
# 4. Updates the ISO
#
# Usage: sudo ./scripts/fix-input-devices.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║     🔧 OBSIDIAN OS - INPUT DEVICE FIX 🔧                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

if [ "$EUID" -ne 0 ]; then
    echo "${RED}This script must be run as root${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

echo "${BLUE}Step 1: Checking rootfs structure...${NC}"

if [ ! -d "rootfs" ]; then
    echo "${RED}ERROR: rootfs directory not found${NC}"
    exit 1
fi

# Check for initramfs-tools
if [ ! -d "rootfs/etc/initramfs-tools" ]; then
    echo "${RED}ERROR: initramfs-tools not found in rootfs${NC}"
    exit 1
fi

echo "${GREEN}✓ Rootfs structure OK${NC}"
echo ""

echo "${BLUE}Step 2: Adding USB HID modules to initramfs...${NC}"

MODULES_FILE="rootfs/etc/initramfs-tools/modules"

# Backup existing file
cp "$MODULES_FILE" "${MODULES_FILE}.backup" 2>/dev/null || true

# Add essential input modules if not present
MODULES_TO_ADD=(
    "usbhid"
    "hid_generic"
    "hid_apple"
    "hid_logitech"
    "hid_microsoft"
    "evdev"
)

for module in "${MODULES_TO_ADD[@]}"; do
    if ! grep -q "^${module}$" "$MODULES_FILE" 2>/dev/null; then
        echo "$module" >> "$MODULES_FILE"
        echo "  Added: $module"
    else
        echo "  Already present: $module"
    fi
done

echo "${GREEN}✓ USB HID modules configured${NC}"
echo ""

echo "${BLUE}Step 3: Checking X11 input drivers in rootfs...${NC}"

# Check if libinput is installed
DPKG_STATUS="rootfs/var/lib/dpkg/status"
LIBINPUT_INSTALLED=false
EVDEV_INSTALLED=false

if [ -f "$DPKG_STATUS" ]; then
    if grep -q "Package: xserver-xorg-input-libinput" "$DPKG_STATUS"; then
        echo "  ${GREEN}✓ xserver-xorg-input-libinput installed${NC}"
        LIBINPUT_INSTALLED=true
    fi
    if grep -q "Package: xserver-xorg-input-evdev" "$DPKG_STATUS"; then
        echo "  ${GREEN}✓ xserver-xorg-input-evdev installed${NC}"
        EVDEV_INSTALLED=true
    fi
fi

if [ "$LIBINPUT_INSTALLED" = false ]; then
    echo "  ${YELLOW}⚠ xserver-xorg-input-libinput not found${NC}"
    echo "  You may need to install it in chroot:"
    echo "    chroot rootfs apt install xserver-xorg-input-libinput"
fi

echo ""

echo "${BLUE}Step 4: Checking X11 configuration...${NC}"

# Check for libinput config
if [ -f "rootfs/usr/share/X11/xorg.conf.d/40-libinput.conf" ]; then
    echo "  ${GREEN}✓ libinput X11 config present${NC}"
else
    echo "  ${YELLOW}⚠ libinput X11 config missing${NC}"
    
    # Create a basic libinput config
    mkdir -p "rootfs/usr/share/X11/xorg.conf.d"
    cat > "rootfs/usr/share/X11/xorg.conf.d/40-libinput.conf" << 'EOF'
# Match all input devices
Section "InputClass"
        Identifier "libinput pointer catchall"
        MatchIsPointer "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput keyboard catchall"
        MatchIsKeyboard "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection
EOF
    echo "  ${GREEN}✓ Created libinput X11 config${NC}"
fi

# Check keyboard layout
if [ -f "rootfs/etc/default/keyboard" ]; then
    LAYOUT=$(grep "XKBLAYOUT" rootfs/etc/default/keyboard | cut -d'"' -f2)
    echo "  Keyboard layout: $LAYOUT"
else
    echo "  ${YELLOW}⚠ No keyboard config found${NC}"
    mkdir -p "rootfs/etc/default"
    cat > "rootfs/etc/default/keyboard" << 'EOF'
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
    echo "  ${GREEN}✓ Created default keyboard config (US layout)${NC}"
fi

echo ""

echo "${BLUE}Step 5: Rebuilding initramfs in chroot...${NC}"

# Mount essential filesystems for chroot
mount --bind /dev rootfs/dev 2>/dev/null || true
mount --bind /dev/pts rootfs/dev/pts 2>/dev/null || true
mount --bind /proc rootfs/proc 2>/dev/null || true
mount --bind /sys rootfs/sys 2>/dev/null || true

# Rebuild initramfs
echo "  Running update-initramfs..."
chroot rootfs /bin/bash -c "update-initramfs -u -k all" 2>&1 | grep -v "^W:" | head -20

# Unmount
umount rootfs/sys 2>/dev/null || true
umount rootfs/proc 2>/dev/null || true
umount rootfs/dev/pts 2>/dev/null || true
umount rootfs/dev 2>/dev/null || true

echo "${GREEN}✓ Initramfs rebuilt${NC}"
echo ""

echo "${BLUE}Step 6: Copying updated initrd to ISO...${NC}"

# Find the initrd
INITRD=$(ls rootfs/boot/initrd.img-* 2>/dev/null | head -1)
if [ -n "$INITRD" ]; then
    cp "$INITRD" iso/obsidian/initrd
    INITRD_SIZE=$(du -h iso/obsidian/initrd | cut -f1)
    echo "  ${GREEN}✓ Copied initrd to iso/obsidian/initrd ($INITRD_SIZE)${NC}"
else
    echo "  ${RED}ERROR: Could not find initrd in rootfs/boot/${NC}"
    exit 1
fi

echo ""

echo "${BLUE}Step 7: Summary${NC}"
echo ""
echo "Modules added to initramfs:"
for module in "${MODULES_TO_ADD[@]}"; do
    echo "  - $module"
done
echo ""
echo "${GREEN}Input device support has been configured!${NC}"
echo ""
echo "Next steps:"
echo "  1. Rebuild squashfs (if you made rootfs changes):"
echo "     mksquashfs rootfs iso/obsidian/filesystem.squashfs -comp zstd -Xcompression-level 15 -b 1M -processors 4 -noappend"
echo ""
echo "  2. Rebuild ISO:"
echo "     ./scripts/rebuild-iso.sh"
echo ""
echo "  3. Run validation:"
echo "     sudo ./scripts/pre-burn-validation.sh"
echo ""
