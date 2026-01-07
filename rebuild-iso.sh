#!/bin/bash
# Obsidian OS - ISO Rebuild Script
# Rebuilds the bootable ISO from the iso/ directory structure

set -e

ISO_NAME="Obsidian-v1.5-Rebranded-$(date +%Y%m%d-%H%M).iso"
ISO_DIR="iso"
OUTPUT_ISO="$ISO_NAME"

echo "🔥 Obsidian OS - ISO Rebuild Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify structure
echo "📂 Verifying ISO structure..."
if [ ! -d "$ISO_DIR" ]; then
    echo "❌ Error: iso/ directory not found"
    exit 1
fi

if [ ! -f "$ISO_DIR/obsidian/vmlinuz" ]; then
    echo "❌ Error: $ISO_DIR/obsidian/vmlinuz not found"
    exit 1
fi

if [ ! -f "$ISO_DIR/obsidian/initrd" ]; then
    echo "❌ Error: $ISO_DIR/obsidian/initrd not found"
    exit 1
fi

if [ ! -f "$ISO_DIR/obsidian/filesystem.squashfs" ]; then
    echo "❌ Error: $ISO_DIR/obsidian/filesystem.squashfs not found"
    exit 1
fi

echo "✅ All required files found"
echo ""

# Check for xorriso
if ! command -v xorriso &> /dev/null; then
    echo "❌ Error: xorriso not installed"
    echo "Install with: apt install xorriso"
    exit 1
fi

echo "🔧 Building ISO with xorriso..."
echo "   Output: $OUTPUT_ISO"
echo ""

# Build ISO with xorriso (hybrid BIOS + UEFI)
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "OBSIDIAN" \
    -appid "Obsidian OS v1.5" \
    -publisher "Obsidian OS Project" \
    -preparer "xorriso" \
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
    -output "$OUTPUT_ISO" \
    "$ISO_DIR"

echo ""
echo "✅ ISO created successfully!"
echo ""

# Generate MD5 checksum
echo "🔐 Generating MD5 checksum..."
md5sum "$OUTPUT_ISO" > "${OUTPUT_ISO}.md5"
echo "✅ Checksum saved to ${OUTPUT_ISO}.md5"
echo ""

# Display info
echo "📊 ISO Information:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$OUTPUT_ISO"
echo ""
cat "${OUTPUT_ISO}.md5"
echo ""
echo "🎉 Done! Your ISO is ready for testing."
echo ""
echo "💡 Test with:"
echo "   qemu-system-x86_64 -cdrom $OUTPUT_ISO -m 4096 -boot d -enable-kvm"
echo ""
