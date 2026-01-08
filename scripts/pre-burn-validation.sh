#!/bin/bash
#
# Obsidian OS - Pre-Burn Validation Suite
# ========================================
# Run this BEFORE burning ISO to USB to catch all known issues
#
# This script validates:
# 1. Boot path case sensitivity (UPPERCASE required)
# 2. All 4 boot config locations
# 3. EFI image embedded configs
# 4. Input device drivers (keyboard/mouse)
# 5. Live boot infrastructure
# 6. Squashfs integrity
# 7. ISO structure and bootability
#
# Usage: sudo ./scripts/pre-burn-validation.sh [ISO_FILE]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Counters
PASS=0
FAIL=0
WARN=0
CRITICAL_FAIL=0

# Logging
LOG_FILE="pre-burn-validation-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

pass() {
    log "${GREEN}✅ PASS:${NC} $1"
    PASS=$((PASS + 1))
}

fail() {
    log "${RED}❌ FAIL:${NC} $1"
    FAIL=$((FAIL + 1))
}

critical() {
    log "${RED}🚨 CRITICAL:${NC} $1"
    CRITICAL_FAIL=$((CRITICAL_FAIL + 1))
    FAIL=$((FAIL + 1))
}

warn() {
    log "${YELLOW}⚠️  WARN:${NC} $1"
    WARN=$((WARN + 1))
}

info() {
    log "${BLUE}ℹ️  INFO:${NC} $1"
}

section() {
    log ""
    log "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${CYAN}${BOLD}  $1${NC}"
    log "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (for mounting EFI images)"
    echo "Usage: sudo $0 [ISO_FILE]"
    exit 1
fi

# Find ISO file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

if [ -n "$1" ]; then
    ISO_FILE="$1"
elif [ -f "Obsidian-v1.7.iso" ]; then
    ISO_FILE="Obsidian-v1.7.iso"
else
    ISO_FILE=$(ls -t *.iso 2>/dev/null | head -1)
fi

if [ ! -f "$ISO_FILE" ]; then
    echo "ERROR: No ISO file found"
    echo "Usage: $0 [ISO_FILE]"
    exit 1
fi

log "╔══════════════════════════════════════════════════════════════════╗"
log "║     🔥 OBSIDIAN OS - PRE-BURN VALIDATION SUITE 🔥                ║"
log "╠══════════════════════════════════════════════════════════════════╣"
log "║ ISO File: $(printf '%-54s' "$ISO_FILE") ║"
log "║ Date:     $(printf '%-54s' "$(date)") ║"
log "║ Log:      $(printf '%-54s' "$LOG_FILE") ║"
log "╚══════════════════════════════════════════════════════════════════╝"

#############################################################################
section "1. CRITICAL: Boot Path Case Sensitivity Check"
#############################################################################
# This is THE most common failure - ISO9660 uses UPPERCASE but configs may have lowercase

info "Checking all 4 boot configuration locations for UPPERCASE paths..."
info "ISO9660 filesystem creates UPPERCASE filenames - configs MUST match"

# Check 1.1: Main GRUB config
if [ -f "iso/boot/grub/grub.cfg" ]; then
    GRUB_PATHS=$(grep -E "(linux|initrd)" iso/boot/grub/grub.cfg | grep -v "^#" | head -5)
    if echo "$GRUB_PATHS" | grep -q "/OBSIDIAN/VMLINUZ"; then
        pass "Main GRUB (iso/boot/grub/grub.cfg): Uses UPPERCASE paths"
    elif echo "$GRUB_PATHS" | grep -q "/obsidian/vmlinuz"; then
        critical "Main GRUB has LOWERCASE paths - WILL FAIL TO BOOT!"
        log "      Found: $(echo "$GRUB_PATHS" | head -1)"
        log "      Fix: sed -i 's|/obsidian/|/OBSIDIAN/|g; s|vmlinuz|VMLINUZ|g; s|initrd|INITRD|g' iso/boot/grub/grub.cfg"
    else
        fail "Main GRUB: Cannot find kernel path references"
    fi
else
    critical "Main GRUB config missing: iso/boot/grub/grub.cfg"
fi

# Check 1.2: ISOLINUX config
if [ -f "iso/isolinux/isolinux.cfg" ]; then
    ISOLINUX_PATHS=$(grep -iE "(kernel|append)" iso/isolinux/isolinux.cfg | grep -v "^#" | head -5)
    if echo "$ISOLINUX_PATHS" | grep -q "/OBSIDIAN/VMLINUZ"; then
        pass "ISOLINUX (iso/isolinux/isolinux.cfg): Uses UPPERCASE paths"
    elif echo "$ISOLINUX_PATHS" | grep -q -i "/obsidian/vmlinuz"; then
        critical "ISOLINUX has LOWERCASE paths - BIOS boot will fail!"
        log "      Found: $(echo "$ISOLINUX_PATHS" | head -1)"
    else
        fail "ISOLINUX: Cannot find kernel path references"
    fi
else
    critical "ISOLINUX config missing: iso/isolinux/isolinux.cfg"
fi

# Check 1.3: EFI Image 1 (iso/boot/grub/efi.img)
EFI1_MOUNT="/tmp/efi1-validate-$$"
if [ -f "iso/boot/grub/efi.img" ]; then
    mkdir -p "$EFI1_MOUNT"
    if mount -o loop,ro iso/boot/grub/efi.img "$EFI1_MOUNT" 2>/dev/null; then
        if [ -f "$EFI1_MOUNT/EFI/boot/grub.cfg" ]; then
            EFI1_PATHS=$(grep -E "(linux|initrd)" "$EFI1_MOUNT/EFI/boot/grub.cfg" 2>/dev/null | head -3)
            if echo "$EFI1_PATHS" | grep -q "/OBSIDIAN/VMLINUZ"; then
                pass "EFI Image 1 (iso/boot/grub/efi.img): Uses UPPERCASE paths"
            elif echo "$EFI1_PATHS" | grep -q "/obsidian/vmlinuz"; then
                critical "EFI Image 1 has LOWERCASE paths - USB UEFI boot will fail!"
                log "      This is embedded in FAT image - run: sudo ./scripts/fix-efi-images.sh"
            else
                fail "EFI Image 1: Cannot find kernel path references"
            fi
        else
            fail "EFI Image 1: No grub.cfg found inside image"
        fi
        umount "$EFI1_MOUNT" 2>/dev/null || true
        rmdir "$EFI1_MOUNT" 2>/dev/null || true
    else
        fail "EFI Image 1: Cannot mount (try running as root)"
    fi
else
    warn "EFI Image 1 not found: iso/boot/grub/efi.img"
fi

# Check 1.4: EFI Image 2 (iso/efi/efi.img)
EFI2_MOUNT="/tmp/efi2-validate-$$"
if [ -f "iso/efi/efi.img" ]; then
    mkdir -p "$EFI2_MOUNT"
    if mount -o loop,ro iso/efi/efi.img "$EFI2_MOUNT" 2>/dev/null; then
        if [ -f "$EFI2_MOUNT/EFI/boot/grub.cfg" ]; then
            EFI2_PATHS=$(grep -E "(linux|initrd)" "$EFI2_MOUNT/EFI/boot/grub.cfg" 2>/dev/null | head -3)
            if echo "$EFI2_PATHS" | grep -q "/OBSIDIAN/VMLINUZ"; then
                pass "EFI Image 2 (iso/efi/efi.img): Uses UPPERCASE paths"
            elif echo "$EFI2_PATHS" | grep -q "/obsidian/vmlinuz"; then
                critical "EFI Image 2 has LOWERCASE paths - USB UEFI boot will fail!"
            else
                fail "EFI Image 2: Cannot find kernel path references"
            fi
        else
            fail "EFI Image 2: No grub.cfg found inside image"
        fi
        umount "$EFI2_MOUNT" 2>/dev/null || true
        rmdir "$EFI2_MOUNT" 2>/dev/null || true
    else
        fail "EFI Image 2: Cannot mount (try running as root)"
    fi
else
    warn "EFI Image 2 not found: iso/efi/efi.img"
fi

#############################################################################
section "2. ISO Structure Verification"
#############################################################################

# Check ISO file
if [ -f "$ISO_FILE" ]; then
    ISO_SIZE=$(stat -c %s "$ISO_FILE")
    ISO_SIZE_MB=$((ISO_SIZE / 1024 / 1024))
    
    if [ "$ISO_SIZE" -gt 500000000 ]; then
        pass "ISO file exists: $ISO_FILE ($ISO_SIZE_MB MB)"
    else
        fail "ISO file too small: $ISO_SIZE_MB MB (expected >500 MB)"
    fi
else
    critical "ISO file not found: $ISO_FILE"
fi

# Check ISO metadata
VOL_ID=$(isoinfo -d -i "$ISO_FILE" 2>/dev/null | grep "Volume id:" | awk '{print $3}')
if [ "$VOL_ID" = "OBSIDIAN" ]; then
    pass "Volume ID: OBSIDIAN"
else
    warn "Volume ID: $VOL_ID (expected OBSIDIAN)"
fi

# List ISO contents and verify UPPERCASE
ISO_CONTENTS=$(isoinfo -l -i "$ISO_FILE" 2>/dev/null)

if echo "$ISO_CONTENTS" | grep -q "/OBSIDIAN"; then
    pass "ISO contains /OBSIDIAN/ directory (UPPERCASE)"
else
    critical "ISO missing /OBSIDIAN/ directory"
fi

if echo "$ISO_CONTENTS" | grep -q "VMLINUZ"; then
    VMLINUZ_SIZE=$(echo "$ISO_CONTENTS" | grep "VMLINUZ" | awk '{print $5}')
    pass "Kernel present: VMLINUZ ($VMLINUZ_SIZE bytes)"
else
    critical "Kernel missing from ISO"
fi

if echo "$ISO_CONTENTS" | grep -q "INITRD"; then
    INITRD_SIZE=$(echo "$ISO_CONTENTS" | grep "INITRD" | awk '{print $5}')
    pass "Initrd present: INITRD ($INITRD_SIZE bytes)"
else
    critical "Initrd missing from ISO"
fi

if echo "$ISO_CONTENTS" | grep -q "FILESYSTEM.SQUASHFS"; then
    pass "Squashfs present: FILESYSTEM.SQUASHFS"
else
    critical "Squashfs missing from ISO"
fi

if echo "$ISO_CONTENTS" | grep -q "BOOTX64.EFI"; then
    pass "UEFI bootloader present: BOOTX64.EFI"
else
    warn "UEFI bootloader not found"
fi

if echo "$ISO_CONTENTS" | grep -q "ISOLINUX.BIN"; then
    pass "BIOS bootloader present: ISOLINUX.BIN"
else
    warn "BIOS bootloader not found"
fi

#############################################################################
section "3. Input Device Support (Keyboard/Mouse)"
#############################################################################

info "Checking for input device drivers (prevents login screen input issues)..."

# Check X11 libinput config
if [ -f "rootfs/usr/share/X11/xorg.conf.d/40-libinput.conf" ]; then
    pass "libinput X11 config present"
else
    warn "libinput X11 config missing - may have input issues"
fi

# Check for evdev/libinput packages
if [ -f "rootfs/var/lib/dpkg/status" ]; then
    if grep -q "Package: xserver-xorg-input-libinput" rootfs/var/lib/dpkg/status 2>/dev/null; then
        pass "xserver-xorg-input-libinput package installed"
    else
        warn "xserver-xorg-input-libinput may be missing"
    fi
    
    if grep -q "Package: xserver-xorg-input-evdev" rootfs/var/lib/dpkg/status 2>/dev/null; then
        pass "xserver-xorg-input-evdev package installed"
    else
        info "xserver-xorg-input-evdev not found (libinput should work instead)"
    fi
fi

# Check keyboard config
if [ -f "rootfs/etc/default/keyboard" ]; then
    XKBLAYOUT=$(grep "XKBLAYOUT" rootfs/etc/default/keyboard | cut -d'"' -f2)
    pass "Keyboard layout configured: $XKBLAYOUT"
else
    warn "Keyboard config missing: /etc/default/keyboard"
fi

# Check if LightDM is configured
if [ -f "rootfs/etc/lightdm/lightdm.conf" ]; then
    pass "LightDM display manager configured"
else
    warn "LightDM config missing"
fi

# Check for USB HID support in initramfs config
INITRAMFS_MODULES="rootfs/etc/initramfs-tools/modules"
if [ -f "$INITRAMFS_MODULES" ]; then
    if grep -q "usbhid\|hid_generic" "$INITRAMFS_MODULES" 2>/dev/null; then
        pass "USB HID modules in initramfs config"
    else
        info "Consider adding to $INITRAMFS_MODULES: usbhid, hid_generic"
    fi
fi

#############################################################################
section "4. Live Boot Infrastructure"
#############################################################################

info "Checking live boot system components..."

# Check for live-boot package
if [ -d "rootfs/lib/live" ] || [ -d "rootfs/usr/lib/live" ]; then
    pass "live-boot system present"
else
    critical "live-boot system missing - ISO will not boot as live system!"
fi

# Check live-media-path in boot configs
if grep -q "live-media-path=/OBSIDIAN" iso/boot/grub/grub.cfg 2>/dev/null; then
    pass "live-media-path set correctly in GRUB"
else
    fail "live-media-path not set or incorrect in GRUB"
fi

if grep -q "live-media-path=/OBSIDIAN" iso/isolinux/isolinux.cfg 2>/dev/null; then
    pass "live-media-path set correctly in ISOLINUX"
else
    fail "live-media-path not set or incorrect in ISOLINUX"
fi

# Check boot=live parameter
if grep -q "boot=live" iso/boot/grub/grub.cfg 2>/dev/null; then
    pass "boot=live parameter present in GRUB"
else
    critical "boot=live parameter missing - will not boot as live system!"
fi

#############################################################################
section "5. Kernel and Initrd Validation"
#############################################################################

# Extract and validate kernel
KERNEL_TMP="/tmp/vmlinuz-validate-$$"
isoinfo -x '/OBSIDIAN/VMLINUZ.;1' -i "$ISO_FILE" > "$KERNEL_TMP" 2>/dev/null

if [ -s "$KERNEL_TMP" ]; then
    KERNEL_TYPE=$(file "$KERNEL_TMP")
    if echo "$KERNEL_TYPE" | grep -q "Linux kernel.*bzImage"; then
        KVER=$(echo "$KERNEL_TYPE" | grep -oP 'version \K[^ ]+' || echo "unknown")
        pass "Kernel is valid bzImage (version: $KVER)"
    else
        fail "Kernel file is not a valid bzImage"
        log "      Type: $KERNEL_TYPE"
    fi
else
    fail "Could not extract kernel from ISO"
fi
rm -f "$KERNEL_TMP"

# Extract and validate initrd
INITRD_TMP="/tmp/initrd-validate-$$"
isoinfo -x '/OBSIDIAN/INITRD.;1' -i "$ISO_FILE" > "$INITRD_TMP" 2>/dev/null

if [ -s "$INITRD_TMP" ]; then
    INITRD_TYPE=$(file "$INITRD_TMP")
    if echo "$INITRD_TYPE" | grep -qE "(gzip|cpio|ASCII cpio|Zstandard)"; then
        INITRD_SIZE=$(stat -c %s "$INITRD_TMP")
        INITRD_SIZE_MB=$((INITRD_SIZE / 1024 / 1024))
        pass "Initrd is valid archive ($INITRD_SIZE_MB MB)"
    else
        fail "Initrd is not a valid archive"
        log "      Type: $INITRD_TYPE"
    fi
else
    fail "Could not extract initrd from ISO"
fi
rm -f "$INITRD_TMP"

#############################################################################
section "6. Squashfs Validation"
#############################################################################

# Check squashfs in source directory
if [ -f "iso/obsidian/filesystem.squashfs" ]; then
    SQFS_SIZE=$(du -h iso/obsidian/filesystem.squashfs | cut -f1)
    SQFS_INFO=$(unsquashfs -s iso/obsidian/filesystem.squashfs 2>/dev/null | head -20)
    
    if echo "$SQFS_INFO" | grep -q "Compression"; then
        COMPRESSION=$(echo "$SQFS_INFO" | grep "Compression" | awk '{print $2}')
        pass "Squashfs valid: $SQFS_SIZE, compression: $COMPRESSION"
    else
        pass "Squashfs present: $SQFS_SIZE"
    fi
    
    # Check squashfs contains essential directories
    for dir in bin etc boot dev lib usr var; do
        if unsquashfs -l iso/obsidian/filesystem.squashfs 2>/dev/null | grep -q "^squashfs-root/${dir}$"; then
            pass "Squashfs contains /$dir"
        else
            fail "Squashfs missing /$dir directory"
        fi
    done
else
    critical "Squashfs not found: iso/obsidian/filesystem.squashfs"
fi

#############################################################################
section "7. MD5 Checksum Verification"
#############################################################################

MD5_FILE="${ISO_FILE}.md5"
if [ -f "$MD5_FILE" ]; then
    if md5sum -c "$MD5_FILE" 2>&1 | grep -q "OK"; then
        pass "MD5 checksum verified"
    else
        critical "MD5 checksum FAILED - ISO may be corrupted!"
    fi
else
    warn "MD5 checksum file not found: $MD5_FILE"
    info "Generating MD5: $(md5sum "$ISO_FILE" | cut -d' ' -f1)"
fi

#############################################################################
section "8. Hybrid Boot Support"
#############################################################################

# Check for MBR/GPT partition table
FDISK_OUTPUT=$(fdisk -l "$ISO_FILE" 2>/dev/null)
if echo "$FDISK_OUTPUT" | grep -q "Disklabel type: dos"; then
    pass "MBR partition table present (BIOS boot support)"
else
    warn "MBR partition table not detected"
fi

if echo "$FDISK_OUTPUT" | grep -q "EFI"; then
    pass "EFI partition detected (UEFI boot support)"
else
    info "EFI partition not in fdisk output (may still work via El Torito)"
fi

#############################################################################
section "9. Default Credentials Check"
#############################################################################

# Check for user configuration
if [ -f "rootfs/etc/passwd" ]; then
    if grep -q "^obsidian:" rootfs/etc/passwd; then
        pass "User 'obsidian' exists in passwd"
    else
        warn "User 'obsidian' not found - check default credentials"
    fi
fi

if [ -f "rootfs/etc/shadow" ]; then
    if grep -q "^obsidian:" rootfs/etc/shadow; then
        # Check if password is set (not locked)
        SHADOW_LINE=$(grep "^obsidian:" rootfs/etc/shadow)
        if echo "$SHADOW_LINE" | grep -qE "obsidian:\$"; then
            pass "User 'obsidian' has password set"
        elif echo "$SHADOW_LINE" | grep -q "obsidian:!"; then
            warn "User 'obsidian' account may be locked"
        else
            pass "User 'obsidian' password entry exists"
        fi
    fi
fi

info "Expected default credentials: obsidian / toor"

#############################################################################
section "10. QEMU Quick Boot Test Recommendation"
#############################################################################

log ""
info "For full verification, run these QEMU tests:"
log ""
log "  ${BOLD}BIOS Boot Test:${NC}"
log "  qemu-system-x86_64 -cdrom $ISO_FILE -m 4096 -boot d"
log ""
log "  ${BOLD}UEFI Boot Test (requires OVMF):${NC}"
log "  qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -cdrom $ISO_FILE -m 4096 -boot d"
log ""
log "  ${BOLD}USB Simulation (tests USB boot path):${NC}"
log "  qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -drive file=$ISO_FILE,format=raw -m 4096"
log ""

#############################################################################
section "SUMMARY"
#############################################################################

log ""
log "╔══════════════════════════════════════════════════════════════════╗"
log "║                      VALIDATION RESULTS                          ║"
log "╠══════════════════════════════════════════════════════════════════╣"
log "║  ${GREEN}Passed:${NC}    $(printf '%3d' $PASS)                                                   ║"
log "║  ${RED}Failed:${NC}    $(printf '%3d' $FAIL)                                                   ║"
log "║  ${YELLOW}Warnings:${NC}  $(printf '%3d' $WARN)                                                   ║"
log "║  ${RED}Critical:${NC}  $(printf '%3d' $CRITICAL_FAIL)                                                   ║"
log "╚══════════════════════════════════════════════════════════════════╝"
log ""

if [ $CRITICAL_FAIL -gt 0 ]; then
    log "${RED}${BOLD}🚨 CRITICAL FAILURES DETECTED - DO NOT BURN TO USB!${NC}"
    log ""
    log "The ISO has critical issues that will prevent booting."
    log "Fix the issues above before burning."
    log ""
    log "Most common fix:"
    log "  sudo ./scripts/fix-efi-images.sh"
    log "  ./scripts/rebuild-iso.sh"
    exit 2
elif [ $FAIL -gt 0 ]; then
    log "${YELLOW}${BOLD}⚠️  SOME TESTS FAILED - Review before burning${NC}"
    log ""
    log "Some non-critical issues found. Review the failures above."
    exit 1
else
    log "${GREEN}${BOLD}✅ ALL TESTS PASSED - Safe to burn to USB!${NC}"
    log ""
    log "ISO Details:"
    log "  File: $ISO_FILE"
    log "  Size: $(du -h "$ISO_FILE" | cut -f1)"
    log "  MD5:  $(md5sum "$ISO_FILE" | cut -d' ' -f1)"
    log ""
    log "Recommended burn method:"
    log "  ${BOLD}Rufus (Windows):${NC} Use DD mode, not ISO mode"
    log "  ${BOLD}Linux:${NC} sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress"
    log ""
    log "Default credentials: obsidian / toor"
    exit 0
fi
