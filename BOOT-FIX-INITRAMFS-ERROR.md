# CRITICAL: Boot Error Fix - Initramfs Unpacking Failed

**Error:** `Initramfs unpacking failed: write error` followed by `Kernel panic - not syncing: No working init found`

**Date:** 2026-01-05 21:31 UTC
**Status:** ⚠️ URGENT FIX REQUIRED

---

## Root Cause Analysis

The error occurs when:
1. **Initramfs is corrupted** - Cannot decompress/unpack
2. **Path mismatch** - Boot loader references wrong path (we changed `/casper` to `/obsidian`)
3. **Initramfs doesn't recognize new path** - Init scripts still look for `/casper`
4. **Insufficient RAM** - VM doesn't have enough memory to unpack initramfs

**Most Likely:** After renaming `/casper` to `/obsidian`, the initramfs still contains scripts that reference `/casper` paths.

---

## Immediate Fix Steps

### Step 1: Verify Boot Configuration
```bash
cd /root/obsidian-build

# Check boot configs reference /obsidian not /casper
cat iso/isolinux/isolinux.cfg
cat iso/boot/grub/grub.cfg

# Should show:
#   KERNEL /obsidian/vmlinuz
#   APPEND initrd=/obsidian/initrd boot=live
```

### Step 2: Check Initramfs Contents
```bash
cd /root/obsidian-build

# Extract initramfs to check for casper references
mkdir -p /tmp/initrd-check
cd /tmp/initrd-check
zcat /root/obsidian-build/iso/obsidian/initrd | cpio -idmv

# Search for casper references in init scripts
grep -r "casper" . 2>/dev/null

# Common problem files:
# - scripts/casper
# - scripts/init-premount/casper
# - conf/initramfs.conf
```

### Step 3: Rebuild Initramfs with Correct Paths

**Option A: Update Existing Initramfs**
```bash
cd /tmp/initrd-check

# Replace all casper references with obsidian
find . -type f -exec sed -i 's|/casper|/obsidian|g' {} \;
find . -type f -exec sed -i 's|casper|obsidian|g' {} \;

# Rebuild initramfs
find . | cpio -H newc -o | gzip -9 > /root/obsidian-build/iso/obsidian/initrd.new
mv /root/obsidian-build/iso/obsidian/initrd.new /root/obsidian-build/iso/obsidian/initrd
```

**Option B: Regenerate from Chroot**
```bash
cd /root/obsidian-build

# Mount chroot
mount --bind /dev rootfs/dev
mount --bind /proc rootfs/proc
mount --bind /sys rootfs/sys

# Regenerate initramfs
chroot rootfs /bin/bash << 'EOF'
# Update initramfs scripts if they exist
if [ -d /usr/share/initramfs-tools/scripts/casper ]; then
    mv /usr/share/initramfs-tools/scripts/casper \
       /usr/share/initramfs-tools/scripts/obsidian
    
    # Update references in scripts
    find /usr/share/initramfs-tools/scripts/obsidian -type f \
         -exec sed -i 's|casper|obsidian|g' {} \;
fi

# Rebuild initramfs
update-initramfs -u -k all

# Copy to ISO
cp /boot/initrd.img-6.1.0-41-amd64 /iso/obsidian/initrd
EOF

# Unmount
umount rootfs/dev rootfs/proc rootfs/sys
```

### Step 4: Alternative - Use Original Casper Path

**If fixes above don't work, revert to /casper:**
```bash
cd /root/obsidian-build/iso

# Rename back to casper
mv obsidian casper

# Update boot configs
sed -i 's|/obsidian/|/casper/|g' isolinux/isolinux.cfg
sed -i 's|/obsidian/|/casper/|g' boot/grub/grub.cfg

# This is NOT ideal but will get it booting
```

---

## Step 5: Test Initramfs Integrity

```bash
# Test if initramfs can be unpacked
cd /tmp
mkdir initrd-test
cd initrd-test
zcat /root/obsidian-build/iso/obsidian/initrd | cpio -t | head -20

# Should list files without errors
# If you get "gzip: invalid compressed data" - initramfs is corrupted
```

---

## Step 6: Check Live Boot Parameter

The boot parameter `boot=live` might need adjustment:

```bash
# Current config should have:
# APPEND initrd=/obsidian/initrd boot=live quiet splash

# Try adding these parameters for debugging:
# APPEND initrd=/obsidian/initrd boot=live debug break=init

# This will drop you to a shell at init time to debug
```

---

## Step 7: Verify Squashfs Filesystem

```bash
# Check if squashfs is valid
unsquashfs -ll /root/obsidian-build/iso/obsidian/filesystem.squashfs | head -20

# Check if init exists in squashfs
unsquashfs -ll /root/obsidian-build/iso/obsidian/filesystem.squashfs | grep "/sbin/init"
unsquashfs -ll /root/obsidian-build/iso/obsidian/filesystem.squashfs | grep "/init"

# Should show:
# lrwxrwxrwx ... squashfs-root/sbin/init -> /lib/systemd/systemd
```

---

## Step 8: Increase VM RAM

If VM has < 2GB RAM:
- Increase to at least 2GB (4GB recommended)
- Initramfs unpacking requires RAM for temporary filesystem

---

## Quick Diagnostic Boot

Add to GRUB/ISOLINUX for debugging:

```
# Debug boot entry
menuentry "Obsidian OS (Debug)" {
    linux /obsidian/vmlinuz boot=live debug break=init ignore_uuid
    initrd /obsidian/initrd
}
```

Or in isolinux.cfg:
```
LABEL obsidian-debug
  MENU LABEL Obsidian OS (Debug)
  KERNEL /obsidian/vmlinuz
  APPEND initrd=/obsidian/initrd boot=live debug break=init
```

---

## Most Likely Solution

Based on the error, the **initramfs scripts still reference `/casper`** even though we renamed the directory to `/obsidian`.

**Execute this fix:**

```bash
#!/bin/bash
cd /root/obsidian-build

echo "Fixing initramfs for /obsidian path..."

# Extract current initramfs
mkdir -p /tmp/initrd-fix
cd /tmp/initrd-fix
zcat /root/obsidian-build/iso/obsidian/initrd | cpio -idm 2>/dev/null

# Replace all casper references
echo "Replacing casper references with obsidian..."
find . -type f -exec grep -l "casper" {} \; 2>/dev/null | while read file; do
    sed -i 's|/casper|/obsidian|g' "$file"
    sed -i 's|CASPER|OBSIDIAN|g' "$file"
    sed -i 's|casper|obsidian|g' "$file"
    echo "Fixed: $file"
done

# Rebuild initramfs
echo "Rebuilding initramfs..."
find . | cpio -H newc -o 2>/dev/null | gzip -9 > /root/obsidian-build/iso/obsidian/initrd

echo "Initramfs fixed! Rebuild ISO and test."

# Rebuild ISO
cd /root/obsidian-build/iso
rm md5sum.txt
find . -type f ! -name md5sum.txt ! -path './isolinux/*' -exec md5sum {} \; > md5sum.txt

cd /root/obsidian-build
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames \
  -volid "OBSIDIAN_1.0" \
  -appid "Obsidian Linux Forged Edition" \
  -publisher "Obsidian Team" \
  -output "Obsidian-v1.0-FIXED-$(date +%Y%m%d-%H%M).iso" \
  -eltorito-boot isolinux/isolinux.bin \
  -eltorito-catalog isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -eltorito-alt-boot \
  -e EFI/boot/bootx64.efi \
  -no-emul-boot -isohybrid-gpt-basdat \
  iso/

echo "✅ Fixed ISO created!"
```

---

## Verification After Fix

1. Boot the fixed ISO in VM
2. Should see Plymouth splash (or boot messages)
3. Should reach desktop without kernel panic
4. Run `cat /proc/cmdline` to verify boot parameters
5. Run `mount | grep obsidian` to verify squashfs mounted

---

## System Status Note

**Current Issue:** System is overloaded from kernel compilation (cannot fork processes)

**Recovery Steps:**
1. Wait for compilation to finish or timeout
2. Reboot the build host if necessary
3. Apply initramfs fix above
4. Test boot in VM

---

## Priority Actions

1. ⚠️ **CRITICAL:** Fix initramfs casper→obsidian references
2. ⚠️ **CRITICAL:** Test boot in VM with at least 2GB RAM
3. 🔄 Regenerate initramfs from chroot if needed
4. ✅ Verify squashfs integrity
5. ✅ Rebuild ISO after fixes

---

**Next ISO should be bootable after applying initramfs path fixes.**
