#!/bin/bash
#############################################
# OBSIDIAN OS v2.0 HARDENED - ISO Builder
#############################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ISO_DIR="$PROJECT_DIR/iso"
OUTPUT_DIR="$PROJECT_DIR"

ISO_NAME="Obsidian-2.0-HARDENED.iso"
VOLUME_ID="OBSIDIAN"
APP_ID="Obsidian OS V2.0 HARDENED"

echo "🔥 OBSIDIAN OS v2.0 HARDENED - ISO Builder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Validate required files
echo "📋 Validating ISO structure..."
for file in "$ISO_DIR/obsidian/vmlinuz" "$ISO_DIR/obsidian/initrd" "$ISO_DIR/obsidian/filesystem.squashfs"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing: $file"
        exit 1
    fi
done
echo "✅ All required files present"

# Fix EFI images BEFORE building ISO (prevent boot errors)
echo "🔧 Verifying EFI image boot configs..."
if [ -f "$ISO_DIR/boot/grub/efi.img" ] && [ -f "$ISO_DIR/efi/efi.img" ]; then
    MOUNT_TMP="/tmp/efi-check-$$"
    mkdir -p "$MOUNT_TMP"
    mount -o loop "$ISO_DIR/boot/grub/efi.img" "$MOUNT_TMP" 2>/dev/null || true
    
    if [ -f "$MOUNT_TMP/EFI/boot/grub.cfg" ]; then
        if grep -q "/obsidian/" "$MOUNT_TMP/EFI/boot/grub.cfg" 2>/dev/null; then
            umount "$MOUNT_TMP" 2>/dev/null || true
            rmdir "$MOUNT_TMP" 2>/dev/null || true
            echo "⚠️  EFI images have lowercase paths - fixing..."
            if [ -x "$SCRIPT_DIR/fix-efi-images.sh" ]; then
                "$SCRIPT_DIR/fix-efi-images.sh"
            fi
        else
            umount "$MOUNT_TMP" 2>/dev/null || true
            rmdir "$MOUNT_TMP" 2>/dev/null || true
            echo "✅ EFI image paths already correct (UPPERCASE)"
        fi
    else
        umount "$MOUNT_TMP" 2>/dev/null || true
        rmdir "$MOUNT_TMP" 2>/dev/null || true
    fi
fi

# Build ISO
echo "📀 Building ISO: $ISO_NAME"
cd "$OUTPUT_DIR"

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "$VOLUME_ID" \
    -appid "$APP_ID" \
    -publisher "Obsidian OS Project" \
    -preparer "Obsidian Build System" \
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
    "$ISO_DIR"

# Generate checksum
echo "🔐 Generating MD5 checksum..."
md5sum "$ISO_NAME" > "${ISO_NAME}.md5"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ BUILD COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📀 ISO: $ISO_NAME"
echo "📊 Size: $(du -h "$ISO_NAME" | cut -f1)"
echo "🔐 MD5: $(cat "${ISO_NAME}.md5")"
echo ""
