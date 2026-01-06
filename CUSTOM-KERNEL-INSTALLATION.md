# Custom Kernel Installation Guide for Obsidian OS

**Status:** Optional Enhancement (System already functional with existing kernel)  
**Date:** 2026-01-05  
**Purpose:** Instructions for building and installing a custom-branded kernel

---

## Overview

The current Obsidian OS ISO uses the standard Debian kernel (`6.1.0-41-amd64`). This guide covers how to:
1. Build a custom kernel with Obsidian branding
2. Install it into the live system
3. Update the ISO with the new kernel

**Note:** This is OPTIONAL. The existing kernel is fully functional.

---

## Prerequisites

```bash
# Install kernel build dependencies
apt-get update
apt-get install -y build-essential linux-source bc kmod cpio flex \
  libncurses5-dev libelf-dev libssl-dev dwarves bison
```

---

## Step 1: Download Kernel Source

```bash
cd /root
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.119.tar.xz
tar -xf linux-6.1.119.tar.xz
cd linux-6.1.119
```

---

## Step 2: Configure Kernel

```bash
# Copy current running config
cp /boot/config-$(uname -r) .config

# Update for new kernel version
make olddefconfig

# (Optional) Customize kernel branding
make menuconfig
# Navigate to: General setup -> Local version
# Set to: -obsidian-forged
# Set kernel compression to XZ or GZIP for smaller size
```

---

## Step 3: Build Kernel

**WARNING:** This takes 2-6 hours depending on CPU cores!

```bash
# Use all CPU cores
make -j$(nproc) bzImage modules

# Expected output:
# - arch/x86/boot/bzImage (kernel image)
# - Compiled kernel modules in various directories
```

**Build time estimates:**
- 4 cores: ~4 hours
- 8 cores: ~2 hours  
- 16 cores: ~1 hour

---

## Step 4: Install Kernel to Build Environment

```bash
cd /root/linux-6.1.119

# Install modules to staging directory
mkdir -p /root/kernel-staging
make INSTALL_MOD_PATH=/root/kernel-staging modules_install

# Copy kernel image
cp arch/x86/boot/bzImage /root/kernel-staging/vmlinuz-6.1.119-obsidian-forged
cp System.map /root/kernel-staging/System.map-6.1.119-obsidian-forged
cp .config /root/kernel-staging/config-6.1.119-obsidian-forged
```

---

## Step 5: Install to Live System Rootfs

```bash
cd /root/obsidian-build

# Copy kernel files to rootfs
cp /root/kernel-staging/vmlinuz-6.1.119-obsidian-forged rootfs/boot/
cp /root/kernel-staging/System.map-6.1.119-obsidian-forged rootfs/boot/
cp /root/kernel-staging/config-6.1.119-obsidian-forged rootfs/boot/

# Copy modules
cp -r /root/kernel-staging/lib/modules/6.1.119-obsidian-forged rootfs/lib/modules/

# Update symlinks
cd rootfs/boot
ln -sf vmlinuz-6.1.119-obsidian-forged vmlinuz
ln -sf System.map-6.1.119-obsidian-forged System.map
```

---

## Step 6: Update Initramfs

```bash
cd /root/obsidian-build

# Mount necessary filesystems for chroot
mount --bind /dev rootfs/dev
mount --bind /proc rootfs/proc
mount --bind /sys rootfs/sys

# Regenerate initramfs with new kernel
chroot rootfs /bin/bash << 'EOF'
# Update module dependencies
depmod -a 6.1.119-obsidian-forged

# Generate initramfs
update-initramfs -c -k 6.1.119-obsidian-forged

# Verify it was created
ls -lh /boot/initrd.img-6.1.119-obsidian-forged
EOF

# Unmount
umount rootfs/dev rootfs/proc rootfs/sys
```

---

## Step 7: Copy Kernel to ISO

```bash
cd /root/obsidian-build

# Copy new kernel and initramfs to ISO directory
cp rootfs/boot/vmlinuz-6.1.119-obsidian-forged iso/obsidian/vmlinuz
cp rootfs/boot/initrd.img-6.1.119-obsidian-forged iso/obsidian/initrd

# Verify sizes (initrd should be ~50-80MB, vmlinuz ~8MB)
ls -lh iso/obsidian/vmlinuz iso/obsidian/initrd
```

---

## Step 8: Rebuild Squashfs

```bash
cd /root/obsidian-build

# Backup existing squashfs
cp iso/obsidian/filesystem.squashfs filesystem.squashfs.backup-kernel

# Rebuild with new kernel modules
mksquashfs rootfs iso/obsidian/filesystem.squashfs \
  -comp xz -b 1M -Xdict-size 100% \
  -noappend

# Verify size
ls -lh iso/obsidian/filesystem.squashfs
```

---

## Step 9: Update Boot Configuration (Optional)

If you want to show the custom kernel version in boot menu:

```bash
cd /root/obsidian-build

# Update GRUB config
nano iso/boot/grub/grub.cfg
# Change: "Start Obsidian OS" 
# To: "Start Obsidian OS (6.1.119-obsidian-forged)"

# Update ISOLINUX config
nano iso/isolinux/isolinux.cfg
# Change: MENU LABEL Start Obsidian OS
# To: MENU LABEL Start Obsidian OS (Custom Kernel)
```

---

## Step 10: Rebuild ISO

```bash
cd /root/obsidian-build

# Update checksums
cd iso
rm -f md5sum.txt
find . -type f ! -name md5sum.txt ! -path './isolinux/*' -exec md5sum {} \; > md5sum.txt

# Build ISO
cd /root/obsidian-build
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames \
  -volid "OBSIDIAN_1.0" \
  -appid "Obsidian Linux Forged Edition" \
  -publisher "Obsidian Team" \
  -output "Obsidian-v1.0-CustomKernel-$(date +%Y%m%d-%H%M).iso" \
  -eltorito-boot isolinux/isolinux.bin \
  -eltorito-catalog isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -eltorito-alt-boot \
  -e EFI/boot/bootx64.efi \
  -no-emul-boot -isohybrid-gpt-basdat \
  iso/

echo "✅ Custom kernel ISO created!"
```

---

## Step 11: Test New ISO

```bash
cd /root/obsidian-build

# Test with QEMU
qemu-system-x86_64 \
  -cdrom Obsidian-v1.0-CustomKernel-*.iso \
  -m 2048 \
  -boot d \
  -enable-kvm

# After boot, verify kernel version:
# uname -r
# Should show: 6.1.119-obsidian-forged
```

---

## Verification Checklist

After booting the custom kernel ISO:

- [ ] System boots without errors
- [ ] `uname -r` shows custom version
- [ ] `uname -a` shows "obsidian-forged" in kernel string
- [ ] All hardware devices work (network, graphics, sound)
- [ ] Plymouth splash screen displays
- [ ] LightDM greeter loads
- [ ] Desktop environment launches

---

## Alternative: Lightweight Branding (No Recompile)

If you just want to show custom branding without kernel recompilation:

```bash
# Method 1: Update /etc/issue and /etc/os-release only
# This changes what's displayed at login, not kernel version

cd /root/obsidian-build/rootfs

# Update OS release info
cat > etc/os-release << 'EOF'
NAME="Obsidian OS"
VERSION="1.0 (Forged Edition)"
ID=obsidian
ID_LIKE=debian
PRETTY_NAME="Obsidian OS 1.0 (Forged Edition)"
VERSION_ID="1.0"
VERSION_CODENAME=forged
HOME_URL="https://obsidianos.example.com"
SUPPORT_URL="https://obsidianos.example.com/support"
BUG_REPORT_URL="https://obsidianos.example.com/bugs"
EOF

# This shows in neofetch, screenfetch, and other system info tools
# But kernel version will still show as Debian's
```

---

## Troubleshooting

### Kernel panic on boot
- Verify initramfs contains correct modules: `lsinitramfs /boot/initrd.img-*`
- Check boot parameters in grub.cfg and isolinux.cfg
- Ensure `/init` exists in initramfs

### Modules not loading
- Run `depmod -a` in chroot before generating initramfs
- Check `/lib/modules/6.1.119-obsidian-forged/modules.dep` exists

### ISO won't boot
- Verify bootloader configs point to correct kernel/initrd paths
- Test with `qemu-system-x86_64 -cdrom [iso] -m 2048`
- Check md5sum.txt was regenerated

### Build fails
- Ensure sufficient disk space (20GB+ free)
- Install all build dependencies
- Check build logs in `/root/linux-6.1.119/`

---

## Time Investment

**Full custom kernel build:** 3-7 hours  
- Download source: 5 minutes
- Configure: 10 minutes  
- Compile: 2-6 hours
- Install & test: 30 minutes

**Lightweight branding only:** 10 minutes  
- Just update /etc/os-release and rebuild squashfs

---

## Recommendation

**For Obsidian OS v1.0:**  
✅ Use existing Debian kernel (current state)  
✅ Focus on userspace branding (themes, ASCII art, aliases)  
⏭️ Plan custom kernel for v2.0 release

**Why:**
1. Existing kernel is stable and tested
2. Kernel compilation takes hours
3. Userspace branding provides 90% of visual impact
4. Custom kernel adds minimal functional value for v1.0

---

## Current Status

✅ **ISO is bootable** with existing kernel (`6.1.0-41-amd64`)  
✅ **Initramfs fixed** - Uses `/obsidian` paths correctly  
✅ **All branding in place** - Plymouth, themes, terminal colors  
⏸️ **Custom kernel** - Optional for future release

**Current working ISO:** `Obsidian-v1.0-Forged-20260105-2150.iso`

---

## Next Steps

**Immediate:**
1. ✅ Test current ISO in VM
2. ✅ Verify Plymouth splash displays
3. ✅ Confirm desktop environment works

**Future (v2.0):**
1. Build custom kernel with branding
2. Add custom kernel modules/drivers
3. Optimize kernel config for target hardware

---

**Document created:** 2026-01-05 21:56 UTC  
**Last updated:** 2026-01-05 21:56 UTC
