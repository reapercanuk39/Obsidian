#!/bin/bash
# Obsidian OS - EFI Image Boot Config Fix
# This script ensures EFI images have UPPERCASE paths matching ISO9660 filesystem

set -e

echo "🔥 Obsidian OS - EFI Image Boot Config Fix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Error: This script must be run as root"
    exit 1
fi

# Verify EFI images exist
EFI_IMG1="iso/boot/grub/efi.img"
EFI_IMG2="iso/efi/efi.img"

if [ ! -f "$EFI_IMG1" ]; then
    echo "❌ Error: $EFI_IMG1 not found"
    exit 1
fi

if [ ! -f "$EFI_IMG2" ]; then
    echo "❌ Error: $EFI_IMG2 not found"
    exit 1
fi

echo "✅ EFI images found"
echo ""

# Create temporary mount points
MOUNT1="/tmp/efi-fix-1"
MOUNT2="/tmp/efi-fix-2"

mkdir -p "$MOUNT1"
mkdir -p "$MOUNT2"

echo "📂 Mounting EFI images..."
echo ""

# Mount EFI Image 1
echo "Mounting: $EFI_IMG1 → $MOUNT1"
mount -o loop "$EFI_IMG1" "$MOUNT1"

# Mount EFI Image 2
echo "Mounting: $EFI_IMG2 → $MOUNT2"
mount -o loop "$EFI_IMG2" "$MOUNT2"

echo "✅ EFI images mounted"
echo ""

# Fix EFI Image 1 grub.cfg
GRUB_CFG1="$MOUNT1/EFI/boot/grub.cfg"

if [ -f "$GRUB_CFG1" ]; then
    echo "🔧 Fixing: $GRUB_CFG1"
    echo "   Before:"
    grep -i "linux\|initrd\|live-media-path" "$GRUB_CFG1" | head -5 || echo "   (no matches)"
    
    # Update all paths to UPPERCASE
    sed -i 's|/obsidian/|/OBSIDIAN/|g' "$GRUB_CFG1"
    sed -i 's|/OBSIDIAN/vmlinuz|/OBSIDIAN/VMLINUZ|g' "$GRUB_CFG1"
    sed -i 's|/OBSIDIAN/initrd|/OBSIDIAN/INITRD|g' "$GRUB_CFG1"
    
    echo "   After:"
    grep -i "linux\|initrd\|live-media-path" "$GRUB_CFG1" | head -5
    echo "   ✅ Fixed"
else
    echo "⚠️  Warning: $GRUB_CFG1 not found"
fi

echo ""

# Fix EFI Image 2 grub.cfg
GRUB_CFG2="$MOUNT2/EFI/boot/grub.cfg"

if [ -f "$GRUB_CFG2" ]; then
    echo "🔧 Fixing: $GRUB_CFG2"
    echo "   Before:"
    grep -i "linux\|initrd\|live-media-path" "$GRUB_CFG2" | head -5 || echo "   (no matches)"
    
    # Update all paths to UPPERCASE
    sed -i 's|/obsidian/|/OBSIDIAN/|g' "$GRUB_CFG2"
    sed -i 's|/OBSIDIAN/vmlinuz|/OBSIDIAN/VMLINUZ|g' "$GRUB_CFG2"
    sed -i 's|/OBSIDIAN/initrd|/OBSIDIAN/INITRD|g' "$GRUB_CFG2"
    
    echo "   After:"
    grep -i "linux\|initrd\|live-media-path" "$GRUB_CFG2" | head -5
    echo "   ✅ Fixed"
else
    echo "⚠️  Warning: $GRUB_CFG2 not found"
fi

echo ""

# Unmount
echo "📤 Unmounting EFI images..."
umount "$MOUNT1"
umount "$MOUNT2"

# Cleanup
rmdir "$MOUNT1"
rmdir "$MOUNT2"

echo "✅ EFI images unmounted"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ EFI IMAGE FIX COMPLETE"
echo ""
echo "All boot configs now use UPPERCASE paths:"
echo "  • /OBSIDIAN/VMLINUZ"
echo "  • /OBSIDIAN/INITRD"
echo "  • live-media-path=/OBSIDIAN"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/rebuild-iso.sh"
echo "  2. Test USB boot on physical hardware"
echo ""
