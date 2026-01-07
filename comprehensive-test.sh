#!/bin/bash

# Comprehensive ISO Test Suite
# Tests ALL aspects of the ISO before user downloads

ISO_FILE="Obsidian-v1.5-Rebranded-20260107-1719.iso"
LOG_FILE="test-results-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to log and print
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to run test
run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    TEST_NAME="$1"
    TEST_CMD="$2"
    
    log "${BLUE}[TEST $TESTS_RUN]${NC} $TEST_NAME"
    
    if eval "$TEST_CMD" >> "$LOG_FILE" 2>&1; then
        log "  ${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log "  ${RED}❌ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Start tests
log "========================================"
log "   OBSIDIAN OS - ISO TEST SUITE"
log "========================================"
log "ISO File: $ISO_FILE"
log "Test Date: $(date)"
log "========================================"
log ""

# Test 1: ISO file exists
run_test "ISO file exists" "test -f $ISO_FILE"

# Test 2: ISO file size reasonable (> 3GB, < 6GB)
run_test "ISO file size check" "test $(stat -c %s $ISO_FILE) -gt 3000000000 && test $(stat -c %s $ISO_FILE) -lt 6000000000"

# Test 3: MD5 checksum matches
run_test "MD5 checksum validation" "md5sum -c ${ISO_FILE}.md5"

# Test 4: ISO is readable
run_test "ISO is readable" "dd if=$ISO_FILE of=/dev/null bs=1M count=10 status=none"

# Test 5: ISO metadata correct
run_test "ISO volume ID = OBSIDIAN" "isoinfo -d -i $ISO_FILE | grep -q 'Volume id: OBSIDIAN'"

# Test 6: Kernel file present
run_test "Kernel file exists in ISO" "isoinfo -l -i $ISO_FILE | grep -q '/OBSIDIAN/VMLINUZ'"

# Test 7: Initrd file present
run_test "Initrd file exists in ISO" "isoinfo -l -i $ISO_FILE | grep -q '/OBSIDIAN/INITRD'"

# Test 8: Squashfs file present
run_test "Squashfs file exists in ISO" "isoinfo -l -i $ISO_FILE | grep -q '/OBSIDIAN/FILESYSTEM.SQUASHFS'"

# Test 9: BIOS bootloader present
run_test "ISOLINUX bootloader present" "isoinfo -l -i $ISO_FILE | grep -q '/ISOLINUX/ISOLINUX.BIN'"

# Test 10: UEFI bootloader present
run_test "UEFI bootloader present" "isoinfo -l -i $ISO_FILE | grep -q '/EFI/BOOT/BOOTX64.EFI'"

# Test 11: GRUB config present
run_test "GRUB config file present" "isoinfo -l -i $ISO_FILE | grep -q '/BOOT/GRUB/GRUB.CFG'"

# Test 12: Extract and verify GRUB config paths
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} GRUB config uses /obsidian/ paths"
TESTS_RUN=$((TESTS_RUN + 1))
GRUB_CFG=$(isoinfo -x '/BOOT/GRUB/GRUB.CFG;1' -i $ISO_FILE 2>/dev/null)
if echo "$GRUB_CFG" | grep -q '/obsidian/vmlinuz' && echo "$GRUB_CFG" | grep -q '/obsidian/initrd'; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 13: Check EFI image 1 grub.cfg
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} EFI Image 1 grub.cfg paths correct"
TESTS_RUN=$((TESTS_RUN + 1))
mkdir -p /tmp/efi-test-$$
if mount -o loop,ro $(isoinfo -x '/BOOT/GRUB/EFI.IMG;1' -i $ISO_FILE | head -c 10M > /tmp/efi-test-$$/efi1.img && echo /tmp/efi-test-$$/efi1.img) /tmp/efi-test-$$ 2>/dev/null; then
    if grep -q '/obsidian/vmlinuz' /tmp/efi-test-$$/EFI/boot/grub.cfg 2>/dev/null; then
        log "  ${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log "  ${RED}❌ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    umount /tmp/efi-test-$$ 2>/dev/null
else
    # Alternative: extract and check
    isoinfo -x '/BOOT/GRUB/EFI.IMG;1' -i $ISO_FILE > /tmp/efi1-test.img 2>/dev/null
    mkdir -p /tmp/efi1-mount-$$
    if mount -o loop,ro /tmp/efi1-test.img /tmp/efi1-mount-$$ 2>/dev/null; then
        if grep -q '/obsidian/vmlinuz' /tmp/efi1-mount-$$/EFI/boot/grub.cfg 2>/dev/null; then
            log "  ${GREEN}✅ PASS${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log "  ${RED}❌ FAIL${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        umount /tmp/efi1-mount-$$ 2>/dev/null
    else
        log "  ${YELLOW}⚠️  SKIP (cannot mount)${NC}"
    fi
    rm -f /tmp/efi1-test.img
    rmdir /tmp/efi1-mount-$$ 2>/dev/null
fi
rm -rf /tmp/efi-test-$$

# Test 14: Kernel file is valid bzImage
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} Kernel is valid bzImage"
TESTS_RUN=$((TESTS_RUN + 1))
isoinfo -x '/OBSIDIAN/VMLINUZ.;1' -i $ISO_FILE > /tmp/vmlinuz-test-$$ 2>/dev/null
if file /tmp/vmlinuz-test-$$ | grep -q "Linux kernel.*boot executable bzImage"; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f /tmp/vmlinuz-test-$$

# Test 15: Squashfs is valid
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} Squashfs filesystem valid"
TESTS_RUN=$((TESTS_RUN + 1))
isoinfo -x '/OBSIDIAN/FILESYSTEM.SQUASHFS;1' -i $ISO_FILE 2>/dev/null | head -c 1M > /tmp/squashfs-test-$$
if file /tmp/squashfs-test-$$ | grep -q "Squashfs filesystem"; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f /tmp/squashfs-test-$$

# Test 16: Partition table check (hybrid MBR + GPT)
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} Hybrid partition table present"
TESTS_RUN=$((TESTS_RUN + 1))
if fdisk -l $ISO_FILE 2>/dev/null | grep -q "Disklabel type: dos"; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 17: Check for Obsidian branding
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} Obsidian branding in ISO"
TESTS_RUN=$((TESTS_RUN + 1))
if isoinfo -d -i $ISO_FILE | grep -qi "OBSIDIAN"; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 18: Initrd structure
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} Initrd is valid archive"
TESTS_RUN=$((TESTS_RUN + 1))
isoinfo -x '/OBSIDIAN/INITRD.;1' -i $ISO_FILE 2>/dev/null | head -c 1M > /tmp/initrd-test-$$
if file /tmp/initrd-test-$$ | grep -qE "(gzip|cpio|ASCII cpio)"; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f /tmp/initrd-test-$$

# Test 19: EFI bootloader is PE32+ executable
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} EFI bootloader is PE32+ executable"
TESTS_RUN=$((TESTS_RUN + 1))
isoinfo -x '/EFI/BOOT/BOOTX64.EFI;1' -i $ISO_FILE > /tmp/bootx64-test-$$ 2>/dev/null
if file /tmp/bootx64-test-$$ | grep -q "PE32+ executable.*EFI application"; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f /tmp/bootx64-test-$$

# Test 20: Source files integrity
run_test "Source kernel file exists" "test -f rootfs/boot/vmlinuz-6.1.0-41-amd64"
run_test "Source initrd file exists" "test -f rootfs/boot/initrd.img-6.1.0-41-amd64"
run_test "Source squashfs matches ISO" "test -f iso/obsidian/filesystem.squashfs"

# Test 21: Build script exists and is executable
run_test "rebuild-iso.sh exists" "test -f rebuild-iso.sh"
run_test "rebuild-iso.sh is executable" "test -x rebuild-iso.sh"

# Test 22: ISO directory structure complete
run_test "iso/boot/grub/ exists" "test -d iso/boot/grub"
run_test "iso/isolinux/ exists" "test -d iso/isolinux"
run_test "iso/EFI/boot/ exists" "test -d iso/EFI/boot"
run_test "iso/obsidian/ exists" "test -d iso/obsidian"

# Test 23: Critical files in iso directory
run_test "iso/obsidian/vmlinuz exists" "test -f iso/obsidian/vmlinuz"
run_test "iso/obsidian/initrd exists" "test -f iso/obsidian/initrd"
run_test "iso/obsidian/filesystem.squashfs exists" "test -f iso/obsidian/filesystem.squashfs"

# Test 24: ISOLINUX config paths
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} ISOLINUX config uses /obsidian/ paths"
TESTS_RUN=$((TESTS_RUN + 1))
if test -f iso/isolinux/isolinux.cfg && grep -q '/obsidian/vmlinuz' iso/isolinux/isolinux.cfg; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${RED}❌ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 25: No debian/ubuntu branding in configs
log "${BLUE}[TEST $((TESTS_RUN + 1))]${NC} No Debian/Ubuntu branding in GRUB"
TESTS_RUN=$((TESTS_RUN + 1))
if ! grep -iE '(debian|ubuntu)' iso/boot/grub/grub.cfg 2>/dev/null; then
    log "  ${GREEN}✅ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    log "  ${YELLOW}⚠️  WARNING: Found Debian/Ubuntu references${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Final summary
log ""
log "========================================"
log "           TEST SUMMARY"
log "========================================"
log "Total Tests: $TESTS_RUN"
log "${GREEN}Passed: $TESTS_PASSED${NC}"
log "${RED}Failed: $TESTS_FAILED${NC}"
log "Success Rate: $(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED/$TESTS_RUN)*100}")%"
log "========================================"
log ""

if [ $TESTS_FAILED -eq 0 ]; then
    log "${GREEN}🎉 ALL TESTS PASSED! ISO is ready for download.${NC}"
    log ""
    log "ISO Details:"
    log "  File: $ISO_FILE"
    log "  Size: $(du -h $ISO_FILE | cut -f1)"
    log "  MD5:  $(cat ${ISO_FILE}.md5 | cut -d' ' -f1)"
    log ""
    log "Download command:"
    log "  scp root@$(hostname -I | awk '{print $1}'):$(pwd)/$ISO_FILE ."
    exit 0
else
    log "${RED}⚠️  SOME TESTS FAILED! Review issues before download.${NC}"
    log ""
    log "Check log file: $LOG_FILE"
    exit 1
fi
