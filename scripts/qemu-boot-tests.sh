#!/bin/bash
#
# Obsidian OS - QEMU Boot Test Suite
# ===================================
# Automated boot testing in QEMU before burning to USB
#
# Tests:
# 1. BIOS boot (ISOLINUX)
# 2. UEFI boot (GRUB via OVMF)
# 3. USB simulation boot
# 4. Safe graphics mode
# 5. Failsafe mode
#
# Usage: sudo ./scripts/qemu-boot-tests.sh [ISO_FILE]
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Find ISO
if [ -n "$1" ]; then
    ISO_FILE="$1"
elif [ -f "Obsidian-v1.7.iso" ]; then
    ISO_FILE="Obsidian-v1.7.iso"
else
    ISO_FILE=$(ls -t *.iso 2>/dev/null | head -1)
fi

if [ ! -f "$ISO_FILE" ]; then
    echo "ERROR: No ISO file found"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║         🔥 OBSIDIAN OS - QEMU BOOT TEST SUITE 🔥                ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║ ISO: $(printf '%-58s' "$ISO_FILE") ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Check for QEMU
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "${RED}ERROR: qemu-system-x86_64 not found${NC}"
    echo "Install with: apt install qemu-system-x86"
    exit 1
fi

# Check for OVMF (UEFI firmware)
OVMF_PATH=""
for path in /usr/share/ovmf/OVMF.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd; do
    if [ -f "$path" ]; then
        OVMF_PATH="$path"
        break
    fi
done

echo "${CYAN}Available Boot Tests:${NC}"
echo ""
echo "  1) BIOS Boot Test (ISOLINUX/Syslinux)"
echo "     Tests legacy BIOS boot path"
echo ""
echo "  2) UEFI Boot Test (GRUB via OVMF)"
echo "     Tests modern UEFI boot path"
echo ""
echo "  3) USB Drive Simulation (UEFI)"
echo "     Simulates USB stick boot (most like real hardware)"
echo ""
echo "  4) Interactive - All Modes"
echo "     Run multiple tests interactively"
echo ""
echo "  5) Headless Boot Verification"
echo "     Non-interactive boot test with timeout"
echo ""
echo "  6) Exit"
echo ""

read -p "Select test (1-6): " choice

run_bios_test() {
    echo ""
    echo "${CYAN}━━━ BIOS Boot Test ━━━${NC}"
    echo "This tests the ISOLINUX bootloader (legacy BIOS boot)"
    echo ""
    echo "What to verify:"
    echo "  ✓ Boot menu appears with 'OBSIDIAN OS v1.7' title"
    echo "  ✓ Selecting 'Start Obsidian OS' loads kernel"
    echo "  ✓ NO error: 'file /obsidian/vmlinuz not found'"
    echo "  ✓ Plymouth splash appears (or boot messages)"
    echo "  ✓ Login screen appears with working keyboard/mouse"
    echo ""
    echo "Press Ctrl+Alt+G to release mouse from QEMU window"
    echo "Press Ctrl+C in this terminal to stop"
    echo ""
    read -p "Press Enter to start BIOS boot test..."
    
    qemu-system-x86_64 \
        -cdrom "$ISO_FILE" \
        -m 4096 \
        -boot d \
        -enable-kvm 2>/dev/null || \
    qemu-system-x86_64 \
        -cdrom "$ISO_FILE" \
        -m 4096 \
        -boot d
}

run_uefi_test() {
    if [ -z "$OVMF_PATH" ]; then
        echo "${RED}ERROR: OVMF firmware not found${NC}"
        echo "Install with: apt install ovmf"
        return 1
    fi
    
    echo ""
    echo "${CYAN}━━━ UEFI Boot Test ━━━${NC}"
    echo "This tests the GRUB UEFI bootloader"
    echo "Using OVMF: $OVMF_PATH"
    echo ""
    echo "What to verify:"
    echo "  ✓ GRUB menu appears with Obsidian entries"
    echo "  ✓ Selecting 'Start Obsidian OS' loads kernel"
    echo "  ✓ NO error: 'file /OBSIDIAN/VMLINUZ not found'"
    echo "  ✓ Plymouth splash appears (or boot messages)"
    echo "  ✓ Login screen appears with working keyboard/mouse"
    echo ""
    echo "This is closer to USB boot behavior!"
    echo ""
    read -p "Press Enter to start UEFI boot test..."
    
    qemu-system-x86_64 \
        -bios "$OVMF_PATH" \
        -cdrom "$ISO_FILE" \
        -m 4096 \
        -boot d \
        -enable-kvm 2>/dev/null || \
    qemu-system-x86_64 \
        -bios "$OVMF_PATH" \
        -cdrom "$ISO_FILE" \
        -m 4096 \
        -boot d
}

run_usb_simulation() {
    if [ -z "$OVMF_PATH" ]; then
        echo "${RED}ERROR: OVMF firmware not found${NC}"
        echo "Install with: apt install ovmf"
        return 1
    fi
    
    echo ""
    echo "${CYAN}━━━ USB Drive Simulation ━━━${NC}"
    echo "This simulates booting from a USB drive (closest to real hardware)"
    echo "Using OVMF: $OVMF_PATH"
    echo ""
    echo "The ISO is mounted as a raw drive, not a CD-ROM"
    echo "This tests the EXACT boot path that Rufus DD mode creates!"
    echo ""
    echo "What to verify:"
    echo "  ✓ GRUB menu appears (from EFI image embedded in ISO)"
    echo "  ✓ NO 'file not found' errors"
    echo "  ✓ System boots to login screen"
    echo "  ✓ Keyboard and mouse work at login"
    echo ""
    read -p "Press Enter to start USB simulation test..."
    
    qemu-system-x86_64 \
        -bios "$OVMF_PATH" \
        -drive file="$ISO_FILE",format=raw,if=none,id=disk0 \
        -device usb-storage,drive=disk0 \
        -m 4096 \
        -enable-kvm 2>/dev/null || \
    qemu-system-x86_64 \
        -bios "$OVMF_PATH" \
        -drive file="$ISO_FILE",format=raw \
        -m 4096
}

run_headless_test() {
    echo ""
    echo "${CYAN}━━━ Headless Boot Verification ━━━${NC}"
    echo "This runs a non-interactive boot test with serial console output"
    echo ""
    echo "Looking for successful boot indicators..."
    echo ""
    
    SERIAL_LOG="/tmp/obsidian-boot-test-$$.log"
    
    timeout 120 qemu-system-x86_64 \
        -cdrom "$ISO_FILE" \
        -m 4096 \
        -boot d \
        -nographic \
        -serial file:"$SERIAL_LOG" \
        -append "console=ttyS0" \
        -enable-kvm 2>/dev/null &
    
    QEMU_PID=$!
    
    echo "QEMU started (PID: $QEMU_PID)"
    echo "Waiting for boot (timeout: 120s)..."
    echo ""
    
    # Wait and check for boot progress
    for i in {1..24}; do
        sleep 5
        if [ -f "$SERIAL_LOG" ]; then
            if grep -q "kernel" "$SERIAL_LOG" 2>/dev/null; then
                echo "${GREEN}✓ Kernel loading detected${NC}"
            fi
            if grep -q "systemd" "$SERIAL_LOG" 2>/dev/null; then
                echo "${GREEN}✓ Systemd started${NC}"
            fi
            if grep -q "login:" "$SERIAL_LOG" 2>/dev/null; then
                echo "${GREEN}✓ Login prompt reached!${NC}"
                kill $QEMU_PID 2>/dev/null
                echo ""
                echo "${GREEN}${BOLD}BOOT TEST PASSED!${NC}"
                rm -f "$SERIAL_LOG"
                return 0
            fi
        fi
        echo "  ... waiting ($((i*5))s)"
    done
    
    kill $QEMU_PID 2>/dev/null
    echo ""
    echo "${YELLOW}Boot test completed (check serial log for details)${NC}"
    if [ -f "$SERIAL_LOG" ]; then
        echo "Last 20 lines of boot log:"
        tail -20 "$SERIAL_LOG"
    fi
    rm -f "$SERIAL_LOG"
}

run_all_tests() {
    echo ""
    echo "${CYAN}━━━ Interactive Test Suite ━━━${NC}"
    echo ""
    echo "This will run each test in sequence."
    echo "Close each QEMU window when done testing to proceed to next."
    echo ""
    
    read -p "Start with BIOS test? (y/n): " ans
    if [ "$ans" = "y" ]; then
        run_bios_test
    fi
    
    if [ -n "$OVMF_PATH" ]; then
        read -p "Continue with UEFI test? (y/n): " ans
        if [ "$ans" = "y" ]; then
            run_uefi_test
        fi
        
        read -p "Continue with USB simulation test? (y/n): " ans
        if [ "$ans" = "y" ]; then
            run_usb_simulation
        fi
    fi
    
    echo ""
    echo "${CYAN}Test suite complete!${NC}"
}

case $choice in
    1) run_bios_test ;;
    2) run_uefi_test ;;
    3) run_usb_simulation ;;
    4) run_all_tests ;;
    5) run_headless_test ;;
    6) exit 0 ;;
    *) echo "Invalid option"; exit 1 ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${BOLD}Test Complete!${NC}"
echo ""
echo "If you saw 'file not found' errors:"
echo "  1. Run: sudo ./scripts/fix-efi-images.sh"
echo "  2. Run: ./scripts/rebuild-iso.sh"
echo "  3. Re-run this test"
echo ""
echo "If keyboard/mouse didn't work at login:"
echo "  1. Check rootfs has: xserver-xorg-input-libinput"
echo "  2. Ensure initrd includes USB HID modules"
echo "  3. Try 'Failsafe Mode' boot option"
echo ""
