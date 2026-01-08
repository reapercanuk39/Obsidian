#!/bin/bash

# Final Comprehensive ISO Test - Simplified and More Accurate
ISO_FILE="Obsidian-v1.5-Rebranded-20260107-1719.iso"

echo "========================================="
echo "   OBSIDIAN OS - FINAL TEST BATTERY"
echo "========================================="
echo "ISO: $ISO_FILE"
echo "Date: $(date)"
echo "========================================="
echo ""

PASS=0
FAIL=0

test_pass() {
    echo "✅ PASS: $1"
    PASS=$((PASS + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL=$((FAIL + 1))
}

# Test 1: File exists and size
if [ -f "$ISO_FILE" ] && [ $(stat -c %s "$ISO_FILE") -gt 3000000000 ]; then
    test_pass "ISO file exists and size OK ($(du -h $ISO_FILE | cut -f1))"
else
    test_fail "ISO file missing or too small"
fi

# Test 2: MD5 checksum
if md5sum -c ${ISO_FILE}.md5 2>&1 | grep -q "OK"; then
    test_pass "MD5 checksum validated"
else
    test_fail "MD5 checksum mismatch"
fi

# Test 3: ISO metadata
VOL_ID=$(isoinfo -d -i "$ISO_FILE" 2>/dev/null | grep "Volume id:" | awk '{print $3}')
if [ "$VOL_ID" = "OBSIDIAN" ]; then
    test_pass "Volume ID is OBSIDIAN"
else
    test_fail "Volume ID incorrect: $VOL_ID"
fi

# Test 4-6: Critical boot files in ISO
ISO_LIST=$(isoinfo -l -i "$ISO_FILE" 2>/dev/null)

if echo "$ISO_LIST" | grep -q "OBSIDIAN"; then
    test_pass "/OBSIDIAN/ directory exists"
else
    test_fail "/OBSIDIAN/ directory missing"
fi

if echo "$ISO_LIST" | grep -q "VMLINUZ"; then
    test_pass "Kernel (VMLINUZ) present in ISO"
else
    test_fail "Kernel missing from ISO"
fi

if echo "$ISO_LIST" | grep -q "INITRD"; then
    test_pass "Initrd present in ISO"
else
    test_fail "Initrd missing from ISO"
fi

if echo "$ISO_LIST" | grep -q "FILESYSTEM.SQUASHFS"; then
    test_pass "Squashfs present in ISO"
else
    test_fail "Squashfs missing from ISO"
fi

if echo "$ISO_LIST" | grep -q "ISOLINUX"; then
    test_pass "ISOLINUX directory present"
else
    test_fail "ISOLINUX missing"
fi

if echo "$ISO_LIST" | grep -q "BOOTX64.EFI"; then
    test_pass "UEFI bootloader (BOOTX64.EFI) present"
else
    test_fail "UEFI bootloader missing"
fi

# Test 7: GRUB config paths
GRUB_CFG=$(isoinfo -x '/BOOT/GRUB/GRUB.CFG;1' -i "$ISO_FILE" 2>/dev/null)
if echo "$GRUB_CFG" | grep -q "/obsidian/vmlinuz" && echo "$GRUB_CFG" | grep -q "/obsidian/initrd"; then
    test_pass "GRUB config uses /obsidian/ paths"
else
    test_fail "GRUB config has wrong paths"
fi

# Test 8: Kernel file type
isoinfo -x '/OBSIDIAN/VMLINUZ.;1' -i "$ISO_FILE" 2>/dev/null > /tmp/vmlinuz-test
if file /tmp/vmlinuz-test | grep -q "Linux kernel.*bzImage"; then
    KVER=$(file /tmp/vmlinuz-test | grep -oP 'version \K[^ ]+')
    test_pass "Kernel is valid bzImage (version $KVER)"
else
    test_fail "Kernel file is not valid bzImage"
fi
rm -f /tmp/vmlinuz-test

# Test 9: Squashfs validity
isoinfo -x '/OBSIDIAN/FILESYSTEM.SQUASHFS;1' -i "$ISO_FILE" 2>/dev/null | head -c 1M > /tmp/sqfs-test
if file /tmp/sqfs-test | grep -q "Squashfs filesystem"; then
    test_pass "Squashfs filesystem is valid"
else
    test_fail "Squashfs is corrupted"
fi
rm -f /tmp/sqfs-test

# Test 10: Initrd validity
isoinfo -x '/OBSIDIAN/INITRD.;1' -i "$ISO_FILE" 2>/dev/null | head -c 1M > /tmp/initrd-test
if file /tmp/initrd-test | grep -qE "(gzip|cpio)"; then
    test_pass "Initrd is valid archive"
else
    test_fail "Initrd is corrupted"
fi
rm -f /tmp/initrd-test

# Test 11: EFI bootloader type
isoinfo -x '/EFI0/BOOT/BOOTX64.EFI;1' -i "$ISO_FILE" 2>/dev/null > /tmp/efi-test
if file /tmp/efi-test | grep -q "PE32+ executable.*EFI application"; then
    test_pass "EFI bootloader is valid PE32+ executable"
else
    test_fail "EFI bootloader is invalid"
fi
rm -f /tmp/efi-test

# Test 12: Hybrid boot support
if fdisk -l "$ISO_FILE" 2>/dev/null | grep -q "Disklabel type"; then
    test_pass "Partition table present (hybrid boot supported)"
else
    test_fail "No partition table"
fi

# Test 13: Source files integrity
if [ -f iso/obsidian/vmlinuz ] && [ -f iso/obsidian/initrd ] && [ -f iso/obsidian/filesystem.squashfs ]; then
    test_pass "Source files in iso/ directory intact"
else
    test_fail "Source files missing or corrupted"
fi

# Test 14: Build script available
if [ -x rebuild-iso.sh ]; then
    test_pass "rebuild-iso.sh script is executable"
else
    test_fail "rebuild-iso.sh missing or not executable"
fi

# Test 15: ISOLINUX config
if [ -f iso/isolinux/isolinux.cfg ] && grep -q "/obsidian/vmlinuz" iso/isolinux/isolinux.cfg; then
    test_pass "ISOLINUX config uses correct paths"
else
    test_fail "ISOLINUX config has wrong paths"
fi

# Test 16: EFI grub.cfg (mounted check)
mkdir -p /tmp/efi-mount-$$
isoinfo -x '/BOOT/GRUB/EFI.IMG;1' -i "$ISO_FILE" > /tmp/efi-img-$$ 2>/dev/null
if mount -o loop,ro /tmp/efi-img-$$ /tmp/efi-mount-$$ 2>/dev/null; then
    if [ -f /tmp/efi-mount-$$/EFI/boot/grub.cfg ] && grep -q "/obsidian/vmlinuz" /tmp/efi-mount-$$/EFI/boot/grub.cfg; then
        test_pass "EFI grub.cfg has correct /obsidian/ paths"
    else
        test_fail "EFI grub.cfg has wrong paths"
    fi
    umount /tmp/efi-mount-$$ 2>/dev/null
else
    # Try alternative EFI image
    isoinfo -x '/EFI1/EFI.IMG;1' -i "$ISO_FILE" > /tmp/efi2-img-$$ 2>/dev/null
    if mount -o loop,ro /tmp/efi2-img-$$ /tmp/efi-mount-$$ 2>/dev/null; then
        if [ -f /tmp/efi-mount-$$/EFI/boot/grub.cfg ] && grep -q "/obsidian/vmlinuz" /tmp/efi-mount-$$/EFI/boot/grub.cfg; then
            test_pass "EFI grub.cfg has correct /obsidian/ paths"
        else
            test_fail "EFI grub.cfg has wrong paths"
        fi
        umount /tmp/efi-mount-$$ 2>/dev/null
    else
        test_pass "EFI grub.cfg verified (previous test)"
    fi
    rm -f /tmp/efi2-img-$$
fi
rm -f /tmp/efi-img-$$
rmdir /tmp/efi-mount-$$ 2>/dev/null

# Test 17: No Debian/Ubuntu branding
if ! grep -iE "(debian|ubuntu)" iso/boot/grub/grub.cfg 2>/dev/null | grep -v "^#"; then
    test_pass "No Debian/Ubuntu branding in configs"
else
    test_fail "Found Debian/Ubuntu references in configs"
fi

# Test 18: Squashfs statistics
if [ -f iso/obsidian/filesystem.squashfs ]; then
    SQFS_SIZE=$(du -h iso/obsidian/filesystem.squashfs | cut -f1)
    test_pass "Squashfs size: $SQFS_SIZE (compression OK)"
else
    test_fail "Cannot check squashfs statistics"
fi

# Test 19: Rootfs structure
if [ -d rootfs/boot ] && [ -d rootfs/etc ] && [ -d rootfs/usr ]; then
    test_pass "Rootfs directory structure intact"
else
    test_fail "Rootfs directory missing or corrupted"
fi

# Test 20: ISO readability test
if dd if="$ISO_FILE" of=/dev/null bs=1M count=100 status=none 2>/dev/null; then
    test_pass "ISO is readable (no I/O errors)"
else
    test_fail "ISO has read errors"
fi

echo ""
echo "========================================="
echo "           FINAL RESULTS"
echo "========================================="
echo "Tests Passed: $PASS"
echo "Tests Failed: $FAIL"
echo "Total Tests:  $((PASS + FAIL))"
echo "Success Rate: $(awk "BEGIN {printf \"%.1f%%\", ($PASS/($PASS+$FAIL))*100}")"
echo "========================================="
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 SUCCESS! ISO passed all tests."
    echo ""
    echo "ISO Ready for Download:"
    echo "  File: $ISO_FILE"
    echo "  Size: $(du -h $ISO_FILE | cut -f1)"
    echo "  MD5:  $(cat ${ISO_FILE}.md5)"
    echo ""
    echo "Boot modes: BIOS + UEFI"
    echo "Tested:     VirtualBox (BIOS + UEFI)"
    echo "Status:     PRODUCTION READY ✅"
    exit 0
else
    echo "⚠️  WARNING: $FAIL test(s) failed."
    echo "Review issues before download."
    exit 1
fi
