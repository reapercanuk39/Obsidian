#!/bin/bash
# Obsidian OS - Deep System Scan for Debian/Ubuntu References

echo "1. KERNEL & BOOT FILES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Current kernel:"
ls -lh rootfs/boot/vmlinuz* 2>/dev/null | head -3
chroot rootfs uname -a 2>/dev/null
echo ""

echo "2. CASPER/LIVE BOOT REFERENCES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Casper directory:"
ls -la iso/casper/ 2>/dev/null | head -5
echo ""
echo "Boot configs mentioning casper:"
grep -r "casper" iso/isolinux/*.cfg iso/boot/grub/*.cfg 2>/dev/null | wc -l
echo "references found"
echo ""

echo "3. USER ACCOUNTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Current users:"
cat rootfs/etc/passwd | grep -E ":/home/|live|linuxuser" | cut -d: -f1,6
echo ""

echo "4. DEBIAN/UBUNTU BRANDING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Debian logos/icons:"
find rootfs/usr/share/pixmaps/ -iname "*debian*" 2>/dev/null | wc -l
echo "Debian icons found"
echo ""
echo "Ubuntu references:"
find rootfs/usr/share/pixmaps/ -iname "*ubuntu*" 2>/dev/null | wc -l
echo "Ubuntu icons found"
echo ""

echo "5. APT REPOSITORIES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Current sources:"
cat rootfs/etc/apt/sources.list 2>/dev/null | grep -v "^#" | head -5
echo ""
ls -la rootfs/etc/apt/sources.list.d/ 2>/dev/null | wc -l
echo "additional source files"
echo ""

echo "6. ISO VOLUME LABEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
isoinfo -d -i Obsidian-v1.0-Forged-20260105-1855.iso 2>/dev/null | grep "Volume id"
echo ""

echo "7. INITRAMFS HOOKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -la rootfs/etc/initramfs-tools/hooks/ 2>/dev/null | head -10
echo ""

echo "8. DESKTOP DEFAULT SETTINGS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -la rootfs/etc/xdg/xfce4/ 2>/dev/null | head -5
echo ""

echo "9. OS RELEASE INFO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat rootfs/etc/os-release 2>/dev/null
echo ""

echo "10. DEBIAN PACKAGES (samples)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chroot rootfs dpkg -l 2>/dev/null | grep -E "^ii" | head -10

