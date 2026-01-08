#!/bin/bash
set -e

echo "=========================================="
echo "   Obsidian OS - XZ Lite ISO Builder"
echo "=========================================="
echo ""

# Configuration
ISO_NAME="Obsidian-v1.6-Enhanced-Lite-$(date +%Y%m%d-%H%M).iso"
SQUASHFS_FILE="iso/obsidian/filesystem.squashfs"

# Step 1: Create squashfs with XZ compression
echo "[1/3] Creating compressed filesystem (XZ compression - this will take ~8 minutes)..."
rm -f "$SQUASHFS_FILE"
mksquashfs rootfs "$SQUASHFS_FILE" \
    -comp xz \
    -Xbcj x86 \
    -b 1M \
    -processors 4 \
    -no-duplicates \
    -progress

# Step 2: Validate ISO structure
echo ""
echo "[2/3] Validating ISO structure..."
required_files=(
    "iso/boot/grub/grub.cfg"
    "iso/isolinux/isolinux.cfg"
    "iso/obsidian/vmlinuz"
    "iso/obsidian/initrd"
    "$SQUASHFS_FILE"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Required file missing: $file"
        exit 1
    fi
done
echo "✓ All required files present"

# Step 3: Build ISO
echo ""
echo "[3/3] Building hybrid ISO..."
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "OBSIDIAN" \
    -eltorito-boot isolinux/isolinux.bin \
    -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output "$ISO_NAME" \
    iso/

# Generate checksum
echo ""
echo "Generating MD5 checksum..."
md5sum "$ISO_NAME" > "${ISO_NAME}.md5"

# Display results
echo ""
echo "=========================================="
echo "            Build Complete!"
echo "=========================================="
echo "ISO File:     $ISO_NAME"
echo "ISO Size:     $(du -h "$ISO_NAME" | cut -f1)"
echo "Squashfs:     $(du -h "$SQUASHFS_FILE" | cut -f1)"
echo "MD5:          $(cat "${ISO_NAME}.md5" | cut -d' ' -f1)"
echo "=========================================="
echo ""
echo "Ready for distribution!"
