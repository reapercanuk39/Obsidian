# Obsidian Linux Distribution - Complete Rebranding Roadmap
**Date:** 2026-01-05  
**Current Status:** Partially branded (Volume ID updated, users renamed, /os-release modified)  
**Goal:** Make Obsidian forensically distinct from Debian/Ubuntu origins

---

## Current State Analysis

### ✅ Already Completed
- [x] ISO Volume ID changed to "OBSIDIAN_1.0"
- [x] `/etc/os-release` updated with Obsidian branding
- [x] User accounts renamed: `obsidian-live` and `obsidian-user` (instead of "live")
- [x] Home directories exist: `/home/obsidian-live/` and `/home/obsidian-user/`

### ❌ Still Shows Debian/Ubuntu Origins
- [ ] **Kernel branding** - Shows `vmlinuz-6.1.0-41-amd64` and `Debian 6.1.158-1` version string
- [ ] **Boot directory** - Still uses `/casper` (Ubuntu/Debian live boot standard)
- [ ] **Boot parameters** - References `boot=live` in isolinux/grub configs
- [ ] **Debian icons** - Desktop-base package contains Debian emblems
- [ ] **APT repositories** - Points to `deb.debian.org`
- [ ] **Debian packages** - `debian-archive-keyring`, `debianutils`, `desktop-base`
- [ ] **Package manager traces** - dpkg shows Debian maintainer info
- [ ] **System alternative links** - `/etc/alternatives/` still points to Debian branding

---

## Priority 1: HIGHEST IMPACT CHANGES (Forensically Visible)

### 1. Custom Kernel Recompilation with Branding
**Current:** `Linux 6.1.0-41-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.158-1 (2025-11-09)`  
**Target:** `Linux 6.1.0-41-obsidian #1 SMP PREEMPT_DYNAMIC Obsidian 6.1.158-forged (2026-01-05)`

**Implementation Path:**
```bash
# Inside rootfs chroot
cd /usr/src/
apt-get install linux-source-6.1 build-essential kernel-package libncurses-dev

# Extract source
tar xaf /usr/src/linux-source-6.1.tar.xz
cd linux-source-6.1/

# Copy current config
cp /boot/config-6.1.0-41-amd64 .config

# Modify kernel version string
sed -i 's/EXTRAVERSION = .*/EXTRAVERSION = -obsidian/' Makefile
sed -i 's/Debian/Obsidian/g' scripts/mkcompile_h
sed -i 's/debian/obsidian/g' scripts/package/mkdebian

# Build custom kernel
make oldconfig
make -j$(nproc) bindeb-pkg LOCALVERSION=-obsidian KDEB_PKGVERSION=6.1.158-forged

# Install custom kernel package
dpkg -i ../linux-image-6.1.0-obsidian_6.1.158-forged_amd64.deb
dpkg -i ../linux-headers-6.1.0-obsidian_6.1.158-forged_amd64.deb

# Remove Debian kernel
apt-get remove --purge linux-image-6.1.0-41-amd64

# Update initramfs
update-initramfs -u -k 6.1.0-obsidian
```

**Files Changed:**
- `/boot/vmlinuz-6.1.0-obsidian`
- `/boot/initrd.img-6.1.0-obsidian`
- `/boot/config-6.1.0-obsidian`
- Kernel version string visible in `uname -a`

**Impact:** ⭐⭐⭐⭐⭐ (Highest - shows in every system info command)

---

### 2. Rename `/casper` to `/obsidian` Boot Directory
**Current:** `/iso/casper/` contains filesystem.squashfs, initrd, vmlinuz  
**Target:** `/iso/obsidian/` 

**Implementation Path:**
```bash
# In iso/ directory
mv casper obsidian

# Update boot configurations
sed -i 's|/casper/|/obsidian/|g' isolinux/isolinux.cfg
sed -i 's|/casper/|/obsidian/|g' boot/grub/grub.cfg
sed -i 's|/casper/|/obsidian/|g' EFI/BOOT/grub.cfg 2>/dev/null

# Update manifest paths if referenced
sed -i 's|casper|obsidian|g' obsidian/filesystem.manifest

# Inside rootfs, update initramfs scripts
sed -i 's|/casper|/obsidian|g' /usr/share/initramfs-tools/scripts/casper 2>/dev/null
# Or create custom initramfs hooks (see Priority 2)

# Rebuild initramfs
update-initramfs -u -k all
```

**Files Changed:**
- `iso/casper/` → `iso/obsidian/`
- `iso/isolinux/isolinux.cfg`
- `iso/boot/grub/grub.cfg`
- `iso/EFI/BOOT/grub.cfg`

**Impact:** ⭐⭐⭐⭐⭐ (Highest - immediately visible in ISO structure)

---

### 3. Remove/Replace Debian Icons and Branding
**Current:** Desktop-base package contains Debian emblems in multiple resolutions  
**Target:** Replace with Obsidian branding

**Implementation Path:**
```bash
# Inside rootfs chroot
cd /usr/share/icons/desktop-base/

# Backup originals (optional)
tar czf /root/debian-icons-backup.tar.gz .

# Replace Debian emblems with custom Obsidian icons
# Create placeholder if no custom icons yet
for size in 64x64 128x128 256x256 scalable; do
  for icon in emblems/emblem-debian*.png emblems/emblem-debian*.svg; do
    if [ -f "$size/$icon" ]; then
      # Option 1: Replace with custom Obsidian icon
      cp /path/to/obsidian-emblem.png "$size/emblems/emblem-obsidian.png"
      
      # Option 2: Create simple colored replacement
      convert -size ${size%x*} xc:#8B00FF "$size/emblems/emblem-obsidian.png"
      
      # Remove Debian originals
      rm "$size/$icon"
    fi
  done
done

# Update alternatives system
update-alternatives --remove-all vendor-logos
update-alternatives --install /etc/alternatives/emblem-vendor \
  emblem-vendor /usr/share/icons/desktop-base/64x64/emblems/emblem-obsidian.png 100

# Remove debian-logos directory
rm -rf /usr/share/desktop-base/debian-logos
mkdir -p /usr/share/desktop-base/obsidian-logos

# Update plymouth splash (if installed)
update-alternatives --set default.plymouth /usr/share/plymouth/themes/obsidian/obsidian.plymouth 2>/dev/null
```

**Packages to Remove/Replace:**
```bash
apt-get remove --purge desktop-base
# Create replacement: obsidian-desktop-base package (see Priority 2)
```

**Impact:** ⭐⭐⭐⭐ (High - visible in desktop environment and file manager)

---

### 4. Custom APT Repository Setup
**Current:** Points to `deb.debian.org`  
**Target:** Primary repo = `repo.obsidian.local`, fallback to Debian if needed

**Implementation Path:**
```bash
# Inside rootfs chroot

# Backup original sources
cp /etc/apt/sources.list /etc/apt/sources.list.debian-backup

# Create new sources.list
cat > /etc/apt/sources.list << 'EOF'
# Obsidian Primary Repository
deb [trusted=yes] http://repo.obsidian.local/obsidian obsidian main contrib non-free
deb-src [trusted=yes] http://repo.obsidian.local/obsidian obsidian main

# Obsidian Security Updates
deb [trusted=yes] http://repo.obsidian.local/obsidian obsidian-security main

# Fallback to Debian (optional - remove for full independence)
# deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
EOF

# Remove Debian keyring (if not using Debian repos)
apt-get remove --purge debian-archive-keyring

# Add custom GPG key
wget -O- https://repo.obsidian.local/obsidian.gpg.key | apt-key add -
# Or for modern apt:
wget -O /etc/apt/trusted.gpg.d/obsidian.asc https://repo.obsidian.local/obsidian.asc

# Create local repository (on build host, not in chroot)
# Using reprepro or aptly
mkdir -p /srv/obsidian-repo/{conf,dists,pool}
cd /srv/obsidian-repo

cat > conf/distributions << 'EOF'
Origin: Obsidian
Label: Obsidian Linux
Codename: obsidian
Architectures: amd64 source
Components: main contrib non-free
Description: Obsidian Linux Official Repository
SignWith: YOUR_GPG_KEY_ID
EOF

# Add custom packages
reprepro includedeb obsidian /path/to/obsidian-base_1.0_all.deb
reprepro includedeb obsidian /path/to/obsidian-desktop_1.0_all.deb
```

**Impact:** ⭐⭐⭐⭐⭐ (Highest - changes entire package ecosystem identity)

---

## Priority 2: MEDIUM IMPACT CHANGES (Installation & Boot)

### 5. Custom Metapackages
**Target Packages:**
- `obsidian-base` - Base system dependencies
- `obsidian-desktop` - Desktop environment config
- `obsidian-tools` - Custom toolset
- `obsidian-live` - Live boot configurations

**Implementation Path:**
```bash
# Create package structure
mkdir -p obsidian-base/DEBIAN
cd obsidian-base

cat > DEBIAN/control << 'EOF'
Package: obsidian-base
Version: 1.0.0
Section: metapackages
Priority: optional
Architecture: all
Depends: systemd, network-manager, sudo, vim, curl, wget
Recommends: obsidian-desktop
Conflicts: debian-archive-keyring
Replaces: base-files
Maintainer: Obsidian Team <team@obsidian.local>
Description: Obsidian Linux base system metapackage
 This metapackage ensures Obsidian base system components
 are installed and configured properly.
EOF

# Add post-installation script
cat > DEBIAN/postinst << 'EOF'
#!/bin/bash
set -e

# Update OS branding files
cat > /etc/issue << 'ISSUE'
Obsidian Linux 1.0 \n \l
ISSUE

cat > /etc/issue.net << 'ISSUE'
Obsidian Linux 1.0
ISSUE

# Update MOTD
cat > /etc/motd << 'MOTD'
  ██████╗ ██████╗ ███████╗██╗██████╗ ██╗ █████╗ ███╗   ██╗
 ██╔═══██╗██╔══██╗██╔════╝██║██╔══██╗██║██╔══██╗████╗  ██║
 ██║   ██║██████╔╝███████╗██║██║  ██║██║███████║██╔██╗ ██║
 ██║   ██║██╔══██╗╚════██║██║██║  ██║██║██╔══██║██║╚██╗██║
 ╚██████╔╝██████╔╝███████║██║██████╔╝██║██║  ██║██║ ╚████║
  ╚═════╝ ╚═════╝ ╚══════╝╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
                    FORGED IN SHADOWS
MOTD

exit 0
EOF

chmod 755 DEBIAN/postinst

# Build package
dpkg-deb --build obsidian-base

# Create desktop metapackage
mkdir -p obsidian-desktop/DEBIAN
cat > obsidian-desktop/DEBIAN/control << 'EOF'
Package: obsidian-desktop
Version: 1.0.0
Section: metapackages
Priority: optional
Architecture: all
Depends: obsidian-base, xfce4, lightdm, firefox-esr, thunar
Provides: desktop-environment
Conflicts: desktop-base
Replaces: desktop-base
Maintainer: Obsidian Team <team@obsidian.local>
Description: Obsidian Linux desktop environment
 Complete desktop environment for Obsidian Linux
EOF

dpkg-deb --build obsidian-desktop
```

**Install in Chroot:**
```bash
dpkg -i obsidian-base_1.0.0_all.deb
dpkg -i obsidian-desktop_1.0.0_all.deb
```

**Impact:** ⭐⭐⭐⭐ (High - establishes package ecosystem)

---

### 6. Custom Initramfs Hooks & Boot Messages
**Target:** Replace "Debian" references in boot process with "Obsidian"

**Implementation Path:**
```bash
# Inside rootfs chroot
mkdir -p /etc/initramfs-tools/hooks
mkdir -p /etc/initramfs-tools/scripts/init-top

# Create custom hook
cat > /etc/initramfs-tools/hooks/obsidian-branding << 'EOF'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions

# Copy Obsidian branding files
cp /etc/obsidian-release "$DESTDIR/etc/"
echo "Obsidian Linux Boot System" > "$DESTDIR/etc/boot-banner"
EOF

chmod +x /etc/initramfs-tools/hooks/obsidian-branding

# Create init script for boot messages
cat > /etc/initramfs-tools/scripts/init-top/obsidian-splash << 'EOF'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

# Display Obsidian boot message
if [ -f /etc/boot-banner ]; then
    cat /etc/boot-banner
fi
echo "Initializing Obsidian Linux..."
EOF

chmod +x /etc/initramfs-tools/scripts/init-top/obsidian-splash

# Update initramfs
update-initramfs -u -k all

# Replace casper scripts if using live boot
if [ -d /usr/share/initramfs-tools/scripts/casper ]; then
    mkdir -p /usr/share/initramfs-tools/scripts/obsidian
    cp -r /usr/share/initramfs-tools/scripts/casper/* \
         /usr/share/initramfs-tools/scripts/obsidian/
    
    # Update references
    sed -i 's/casper/obsidian/g' /usr/share/initramfs-tools/scripts/obsidian/*
    sed -i 's/Debian/Obsidian/g' /usr/share/initramfs-tools/scripts/obsidian/*
fi
```

**Impact:** ⭐⭐⭐ (Medium - visible during boot sequence)

---

### 7. Boot Configuration Updates
**Target:** Change `boot=live` to `boot=obsidian`

**Implementation Path:**
```bash
# Update isolinux
sed -i 's/boot=live/boot=obsidian/g' iso/isolinux/isolinux.cfg

# Update GRUB
sed -i 's/boot=live/boot=obsidian/g' iso/boot/grub/grub.cfg
sed -i 's/boot=live/boot=obsidian/g' iso/EFI/BOOT/grub.cfg

# Update boot splash if present
sed -i 's/Debian/Obsidian/g' iso/isolinux/splash.png 2>/dev/null
sed -i 's/Debian/Obsidian/g' iso/boot/grub/splash.png 2>/dev/null

# Inside rootfs, update initramfs to recognize boot=obsidian
# This requires modifying live-boot or casper scripts
cd /usr/share/initramfs-tools/scripts/
grep -r "boot=live" . | cut -d: -f1 | sort -u | while read file; do
    sed -i 's/boot=live/boot=obsidian/g' "$file"
done

update-initramfs -u -k all
```

**Impact:** ⭐⭐⭐ (Medium - changes boot parameter but requires script support)

---

## Priority 3: DEEP BRANDING (Installer & Post-Install)

### 8. Custom Desktop Environment Tweaks
**Target Package:** `obsidian-default-settings`

**Implementation Path:**
```bash
# Create settings package
mkdir -p obsidian-default-settings/DEBIAN
mkdir -p obsidian-default-settings/etc/skel/.config

cat > obsidian-default-settings/DEBIAN/control << 'EOF'
Package: obsidian-default-settings
Version: 1.0.0
Section: misc
Priority: optional
Architecture: all
Depends: obsidian-desktop
Maintainer: Obsidian Team <team@obsidian.local>
Description: Default settings for Obsidian Linux desktop
 Configures XFCE, themes, wallpapers, and default applications
EOF

# Add XFCE customizations
cat > obsidian-default-settings/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="image-path" type="string" value="/usr/share/backgrounds/obsidian-default.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

# Create default wallpaper
mkdir -p obsidian-default-settings/usr/share/backgrounds
# Add custom Obsidian wallpaper here

# Set default theme
mkdir -p obsidian-default-settings/usr/share/themes/Obsidian-Dark
# Add GTK theme files

dpkg-deb --build obsidian-default-settings
```

**Impact:** ⭐⭐⭐ (Medium - improves user experience branding)

---

### 9. Debian Package Removal List
**Packages to Remove:**
```bash
apt-get remove --purge \
  debian-archive-keyring \
  desktop-base \
  debian-reference-common \
  debian-faq \
  doc-debian \
  popularity-contest
```

**Files to Clean:**
```bash
# Remove Debian references from debianutils (if keeping package)
rm -f /usr/share/doc/debianutils/README.Debian*
rm -f /usr/share/man/*/man1/which.debianutils.*

# Clean documentation
find /usr/share/doc -name "*debian*" -type d -exec rm -rf {} + 2>/dev/null

# Remove Debian-specific scripts
rm -f /usr/sbin/debian-* 2>/dev/null
rm -f /usr/bin/debian-* 2>/dev/null
```

**Impact:** ⭐⭐ (Low-Medium - reduces Debian footprint)

---

### 10. Custom Installer Modifications (If Using Debian Installer)
**Target:** Create `obsidian-installer` based on debian-installer

**Implementation Path:**
```bash
# This is complex - requires forking debian-installer
# Key files to modify:

# 1. Partition preseeding
cat > obsidian-installer-preseed.cfg << 'EOF'
# Obsidian custom partitioning
d-i partman-auto/disk string /dev/sda
d-i partman-auto/method string regular
d-i partman-auto/expert_recipe string \
  obsidian-layout :: \
    1024 1024 1024 ext4 \
      $primary{ } $bootable{ } \
      method{ format } format{ } \
      use_filesystem{ } filesystem{ ext4 } \
      mountpoint{ /boot } \
      label{ OBSIDIAN_BOOT } \
    . \
    16384 16384 16384 linux-swap \
      method{ swap } format{ } \
      label{ OBSIDIAN_SWAP } \
    . \
    20480 20480 -1 ext4 \
      method{ format } format{ } \
      use_filesystem{ } filesystem{ ext4 } \
      mountpoint{ / } \
      label{ OBSIDIAN_ROOT } \
    .
EOF

# 2. Update installer branding
# Fork debian-installer from Debian sources
# Modify build/config files to reference Obsidian

# 3. Use calamares installer instead (easier alternative)
apt-get install calamares
# Configure /etc/calamares/settings.conf with Obsidian branding
```

**Impact:** ⭐⭐⭐⭐ (High - fully custom installation experience)

---

## Implementation Timeline

### Phase 1: Critical Rebranding (2-3 days)
1. ✅ Rename `/casper` to `/obsidian` 
2. ✅ Custom kernel compilation with version string
3. ✅ Remove Debian icons and replace with Obsidian branding
4. ✅ Update boot configurations (isolinux, grub)

### Phase 2: Package Ecosystem (3-4 days)
5. ✅ Create custom APT repository
6. ✅ Build obsidian-base metapackage
7. ✅ Build obsidian-desktop metapackage
8. ✅ Remove Debian-specific packages

### Phase 3: Polish & Testing (2-3 days)
9. ✅ Custom initramfs hooks
10. ✅ Desktop environment settings package
11. ✅ Test full boot-to-desktop cycle
12. ✅ Forensic verification (no Debian traces)

---

## Verification Checklist

After completing all changes, verify Obsidian is forensically distinct:

```bash
# 1. Check kernel version
uname -a
# Should show: Linux 6.1.0-obsidian ... Obsidian 6.1.158-forged

# 2. Check OS release
cat /etc/os-release
# Should show: NAME="Obsidian" ID=obsidian

# 3. Check ISO structure
isoinfo -d -i Obsidian.iso
# Volume id: OBSIDIAN_1.0
# Check for /obsidian not /casper

# 4. Check for Debian references
grep -ri "debian" /etc/ 2>/dev/null | grep -v ".cache" | wc -l
# Should be 0 or minimal

# 5. Check installed packages
dpkg -l | grep -i debian
# Should show no debian-specific packages

# 6. Check APT sources
cat /etc/apt/sources.list
# Should point to repo.obsidian.local

# 7. Check alternatives system
ls -la /etc/alternatives/ | grep -i debian
# Should show no Debian references

# 8. Check boot messages
dmesg | grep -i debian
# Should show no Debian references

# 9. Check icons
find /usr/share/icons -name "*debian*"
# Should return nothing

# 10. Check user accounts
cat /etc/passwd | grep -E "(live|debian)"
# Should show no generic "live" user (only obsidian-live if intentional)
```

---

## Automation Script

Create `rebrand-obsidian.sh`:

```bash
#!/bin/bash
# Obsidian Complete Rebranding Automation Script

set -e

ROOTFS_DIR="/root/obsidian-build/rootfs"
ISO_DIR="/root/obsidian-build/iso"

echo "=== Obsidian Rebranding Automation ==="

# Phase 1: Casper to Obsidian
echo "[1/10] Renaming /casper to /obsidian..."
cd "$ISO_DIR"
if [ -d "casper" ]; then
    mv casper obsidian
    sed -i 's|/casper/|/obsidian/|g' isolinux/isolinux.cfg
    sed -i 's|/casper/|/obsidian/|g' boot/grub/grub.cfg
    sed -i 's|boot=live|boot=obsidian|g' isolinux/isolinux.cfg boot/grub/grub.cfg
fi

# Phase 2: Chroot operations
echo "[2/10] Entering chroot for deep modifications..."
mount --bind /dev "$ROOTFS_DIR/dev"
mount --bind /proc "$ROOTFS_DIR/proc"
mount --bind /sys "$ROOTFS_DIR/sys"

chroot "$ROOTFS_DIR" /bin/bash << 'CHROOT_EOF'
export DEBIAN_FRONTEND=noninteractive

# Remove Debian packages
echo "[3/10] Removing Debian-specific packages..."
apt-get remove --purge -y debian-archive-keyring desktop-base || true

# Update APT sources
echo "[4/10] Configuring Obsidian repository..."
cat > /etc/apt/sources.list << 'EOF'
deb [trusted=yes] http://repo.obsidian.local/obsidian obsidian main
EOF

# Remove Debian icons
echo "[5/10] Removing Debian icons..."
find /usr/share/icons -name "*debian*" -delete 2>/dev/null || true

# Update initramfs
echo "[6/10] Rebuilding initramfs..."
update-initramfs -u -k all

CHROOT_EOF

# Cleanup mounts
umount "$ROOTFS_DIR/dev" "$ROOTFS_DIR/proc" "$ROOTFS_DIR/sys"

echo "[7/10] Repackaging filesystem.squashfs..."
mksquashfs "$ROOTFS_DIR" "$ISO_DIR/obsidian/filesystem.squashfs" \
  -comp xz -b 1M -Xdict-size 100% -noappend

echo "[8/10] Updating manifests..."
chroot "$ROOTFS_DIR" dpkg-query -W --showformat='${Package} ${Version}\n' \
  > "$ISO_DIR/obsidian/filesystem.manifest"

echo "[9/10] Rebuilding ISO..."
xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "OBSIDIAN_1.0" \
  -appid "Obsidian Linux Forged Edition" \
  -publisher "Obsidian Team" \
  -output "Obsidian-Rebranded-$(date +%Y%m%d).iso" \
  -eltorito-boot isolinux/isolinux.bin \
  -eltorito-catalog isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -eltorito-alt-boot \
  -e EFI/BOOT/BOOTX64.EFI \
  -no-emul-boot -isohybrid-gpt-basdat \
  "$ISO_DIR"

echo "[10/10] Rebranding complete!"
echo "New ISO: Obsidian-Rebranded-$(date +%Y%m%d).iso"
```

---

## Conclusion

**Biggest Impact Changes (Do These First):**
1. ✅ Rename `/casper` → `/obsidian` 
2. ✅ Custom kernel with "Obsidian" version string
3. ✅ Remove all Debian icons/emblems
4. ✅ Custom APT repository (repo.obsidian.local)
5. ✅ Create obsidian-base & obsidian-desktop metapackages

**Result:** Obsidian Linux will be forensically distinct from Debian with no obvious traces linking back to Debian infrastructure, branding, or package management.

**Estimated Total Effort:** 7-10 days for complete implementation
**Maintenance:** Custom kernel requires periodic security updates tracking
