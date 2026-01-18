#!/bin/bash
#############################################
# OBSIDIAN ISO VIRTUALBOX BOOT TEST
# Graphical boot testing with VirtualBox
# Captures screenshots at key boot stages
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

#############################################
# CONFIG
#############################################

ISO_PATH="${1:-$PROJECT_DIR/Obsidian-2.1-FORTRESS.iso}"
VM_NAME="${VM_NAME:-ObsidianTestVM-$$}"
TIMEOUT="${BOOT_TIMEOUT:-300}"  # 5 minutes default
MEMORY="${VBOX_MEMORY:-2048}"
CPUS="${VBOX_CPUS:-2}"
VRAM="${VBOX_VRAM:-64}"
DISK_SIZE="${VBOX_DISK_SIZE:-8192}"  # 8GB virtual disk

# Screenshot intervals (seconds after boot start)
SCREENSHOT_TIMES="${SCREENSHOT_TIMES:-5 15 30 60 120 180}"

# Output directories
WORK_DIR="/tmp/virtualbox-boot-test-$$"
ARTIFACT_DIR="${ARTIFACT_DIR:-$PROJECT_DIR/artifacts/virtualbox}"
SCREENSHOT_DIR="$ARTIFACT_DIR/screenshots"
LOG_DIR="$ARTIFACT_DIR/logs"
FAILURE_DIR="$PROJECT_DIR/artifacts/failures/virtualbox"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#############################################
# CLEANUP HANDLER
#############################################

cleanup() {
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    
    # Power off and delete VM
    if VBoxManage showvminfo "$VM_NAME" &>/dev/null 2>&1; then
        VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
        sleep 2
        VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
    fi
    
    # Remove work directory
    rm -rf "$WORK_DIR"
    
    echo "Artifacts saved to: $ARTIFACT_DIR"
}
trap cleanup EXIT

#############################################
# HELPER FUNCTIONS
#############################################

log_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📋 $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_test() {
    local status="$1"
    local name="$2"
    local details="${3:-}"
    
    case "$status" in
        PASS)
            echo -e "${GREEN}✓ PASS${NC}: $name"
            TEST_RESULTS="${TEST_RESULTS}PASS|$name|$details\n"
            ((TESTS_PASSED++))
            ;;
        FAIL)
            echo -e "${RED}✗ FAIL${NC}: $name"
            TEST_RESULTS="${TEST_RESULTS}FAIL|$name|$details\n"
            ((TESTS_FAILED++))
            ;;
    esac
}

check_tool() {
    if ! command -v "$1" &>/dev/null; then
        log_error "Required tool not found: $1"
        echo "Install with: $2"
        return 1
    fi
}

capture_screenshot() {
    local name="$1"
    local timestamp="$(date +%Y%m%d-%H%M%S)"
    local filename="${timestamp}-${name}.png"
    
    log_info "Capturing screenshot: $filename"
    VBoxManage controlvm "$VM_NAME" screenshotpng "$SCREENSHOT_DIR/$filename" 2>/dev/null || true
}

analyze_screenshot() {
    local screenshot="$1"
    local expected_pattern="$2"
    
    # Basic validation - check if screenshot was captured and has content
    if [ -f "$screenshot" ] && [ -s "$screenshot" ]; then
        local size=$(stat -c%s "$screenshot" 2>/dev/null || echo "0")
        if [ "$size" -gt 1000 ]; then
            return 0  # Screenshot appears valid
        fi
    fi
    return 1
}

get_vm_state() {
    VBoxManage showvminfo "$VM_NAME" --machinereadable 2>/dev/null | grep "^VMState=" | cut -d'"' -f2 || echo "unknown"
}

wait_for_boot_stage() {
    local stage="$1"
    local timeout="$2"
    local elapsed=0
    
    log_info "Waiting for boot stage: $stage (timeout: ${timeout}s)"
    
    while [ "$elapsed" -lt "$timeout" ]; do
        local state=$(get_vm_state)
        
        if [ "$state" = "running" ]; then
            # VM is running, capture screenshot to analyze
            return 0
        elif [ "$state" = "poweroff" ] || [ "$state" = "aborted" ]; then
            log_error "VM stopped unexpectedly (state: $state)"
            return 1
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    return 1
}

#############################################
# SETUP
#############################################

log_step "Checking Prerequisites"

# Check for VirtualBox CLI
if ! check_tool "VBoxManage" "apt install virtualbox || download from virtualbox.org"; then
    exit 1
fi

# Verify ISO exists
if [ ! -f "$ISO_PATH" ]; then
    log_error "ISO not found: $ISO_PATH"
    exit 1
fi

# Check VirtualBox version
VBOX_VERSION=$(VBoxManage --version 2>/dev/null || echo "unknown")
log_info "VirtualBox version: $VBOX_VERSION"

# Create directories
mkdir -p "$WORK_DIR" "$SCREENSHOT_DIR" "$LOG_DIR" "$FAILURE_DIR"

# Print configuration
echo ""
echo "🖥️  VIRTUALBOX BOOT TEST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ISO:         $(basename "$ISO_PATH")"
echo "  VM Name:     $VM_NAME"
echo "  Memory:      ${MEMORY}MB"
echo "  CPUs:        $CPUS"
echo "  Timeout:     ${TIMEOUT}s"
echo "  Screenshots: $SCREENSHOT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#############################################
# RUN - CREATE VM
#############################################

log_step "Creating VirtualBox VM"

# Create VM
log_info "Creating VM: $VM_NAME"
VBoxManage createvm --name "$VM_NAME" --ostype "Debian_64" --register

# Configure VM
log_info "Configuring VM resources..."
VBoxManage modifyvm "$VM_NAME" \
    --memory "$MEMORY" \
    --cpus "$CPUS" \
    --vram "$VRAM" \
    --graphicscontroller vmsvga \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none \
    --audio-driver none \
    --nic1 nat \
    --nictype1 virtio \
    --rtcuseutc on \
    --clipboard-mode disabled \
    --vrde on \
    --vrdeport 5901 \
    --vrdemulticon on

# Enable EFI if available (fallback to BIOS)
if VBoxManage modifyvm "$VM_NAME" --firmware efi 2>/dev/null; then
    log_info "EFI firmware enabled"
else
    log_warning "EFI not available, using BIOS"
fi

# Create storage controller
log_info "Creating storage controller..."
VBoxManage storagectl "$VM_NAME" \
    --name "SATA Controller" \
    --add sata \
    --controller IntelAHCI \
    --portcount 2

# Create virtual disk for potential install testing
VDISK_PATH="$WORK_DIR/${VM_NAME}.vdi"
log_info "Creating virtual disk: $VDISK_PATH"
VBoxManage createhd --filename "$VDISK_PATH" --size "$DISK_SIZE" --format VDI

# Attach virtual disk
VBoxManage storageattach "$VM_NAME" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "$VDISK_PATH"

# Attach ISO
log_info "Attaching ISO: $ISO_PATH"
VBoxManage storageattach "$VM_NAME" \
    --storagectl "SATA Controller" \
    --port 1 \
    --device 0 \
    --type dvddrive \
    --medium "$ISO_PATH"

log_success "VM created successfully"

# Get VM info
VBoxManage showvminfo "$VM_NAME" --machinereadable > "$LOG_DIR/vm-config.txt"

#############################################
# RUN - START VM AND CAPTURE SCREENSHOTS
#############################################

log_step "Starting VM and Running Boot Tests"

# Start VM headless (or with VNC if available)
log_info "Starting VM in headless mode..."
VBoxManage startvm "$VM_NAME" --type headless

# Wait for VM to start
sleep 3

# Verify VM is running
VM_STATE=$(get_vm_state)
if [ "$VM_STATE" != "running" ]; then
    log_test FAIL "VM startup" "VM state: $VM_STATE"
    exit 1
fi
log_test PASS "VM startup" "VM is running"

# Capture initial screenshots and boot stages
BOOT_START_TIME=$(date +%s)
LAST_SCREENSHOT_TIME=$BOOT_START_TIME

# Screenshot capture loop
for screenshot_interval in $SCREENSHOT_TIMES; do
    # Wait until it's time for this screenshot
    while true; do
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - BOOT_START_TIME))
        
        if [ "$ELAPSED" -ge "$screenshot_interval" ]; then
            break
        fi
        
        # Check if VM is still running
        VM_STATE=$(get_vm_state)
        if [ "$VM_STATE" != "running" ]; then
            log_warning "VM stopped during boot (state: $VM_STATE)"
            break 2
        fi
        
        sleep 1
    done
    
    # Capture screenshot
    case "$screenshot_interval" in
        5)   capture_screenshot "01-bios-bootloader" ;;
        15)  capture_screenshot "02-isolinux-menu" ;;
        30)  capture_screenshot "03-kernel-loading" ;;
        60)  capture_screenshot "04-initramfs" ;;
        120) capture_screenshot "05-system-services" ;;
        180) capture_screenshot "06-desktop-login" ;;
        *)   capture_screenshot "stage-${screenshot_interval}s" ;;
    esac
    
    # Check boot progress after capture
    VM_STATE=$(get_vm_state)
    if [ "$VM_STATE" != "running" ]; then
        log_warning "VM stopped at ${screenshot_interval}s mark"
        break
    fi
    
    # Record elapsed time
    CURRENT_ELAPSED=$(($(date +%s) - BOOT_START_TIME))
    log_info "Boot progress: ${CURRENT_ELAPSED}s elapsed, VM state: $VM_STATE"
done

#############################################
# RUN - VALIDATE BOOT SUCCESS
#############################################

log_step "Validating Boot Success"

# Final VM state check
VM_STATE=$(get_vm_state)
TOTAL_ELAPSED=$(($(date +%s) - BOOT_START_TIME))

log_info "Total boot time: ${TOTAL_ELAPSED}s"
log_info "Final VM state: $VM_STATE"

# Test: VM still running after boot time
if [ "$VM_STATE" = "running" ]; then
    if [ "$TOTAL_ELAPSED" -ge 120 ]; then
        log_test PASS "Boot stability" "VM running for ${TOTAL_ELAPSED}s"
    else
        log_test FAIL "Boot stability" "VM only ran for ${TOTAL_ELAPSED}s"
    fi
else
    log_test FAIL "Boot stability" "VM stopped with state: $VM_STATE"
fi

# Capture final screenshot
capture_screenshot "99-final-state"

# Test: Screenshots were captured
SCREENSHOT_COUNT=$(ls -1 "$SCREENSHOT_DIR"/*.png 2>/dev/null | wc -l)
if [ "$SCREENSHOT_COUNT" -ge 3 ]; then
    log_test PASS "Screenshot capture" "Captured $SCREENSHOT_COUNT screenshots"
else
    log_test FAIL "Screenshot capture" "Only $SCREENSHOT_COUNT screenshots captured"
fi

# Test: VM console output (via guest additions if available)
# This is a best-effort check - may not work without guest additions
VRDE_LOG="$LOG_DIR/vrde-output.log"
VBoxManage controlvm "$VM_NAME" keyboardputscancode 1c 9c 2>/dev/null || true  # Press Enter
sleep 1
capture_screenshot "99-after-keypress"

#############################################
# CLEANUP - STOP VM
#############################################

log_step "Stopping VM"

# Save state for debugging if failed
if [ "$TESTS_FAILED" -gt 0 ]; then
    log_info "Saving VM state for debugging..."
    VBoxManage controlvm "$VM_NAME" savestate 2>/dev/null || true
    sleep 2
fi

# Power off
VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
sleep 2

# Collect VM logs
log_info "Collecting VM logs..."
VM_LOG_PATH="$HOME/VirtualBox VMs/$VM_NAME/Logs/VBox.log"
if [ -f "$VM_LOG_PATH" ]; then
    cp "$VM_LOG_PATH" "$LOG_DIR/VBox.log"
fi

#############################################
# GENERATE SUMMARY
#############################################

log_step "Generating Test Summary"

SUMMARY_FILE="$ARTIFACT_DIR/SUMMARY.md"
TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

cat > "$SUMMARY_FILE" << EOF
# VirtualBox Boot Test Summary

**ISO:** \`$(basename "$ISO_PATH")\`  
**VM Name:** \`$VM_NAME\`  
**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")  
**Boot Duration:** ${TOTAL_ELAPSED}s  

## Results

| Status | Count |
|--------|-------|
| ✅ Passed | $TESTS_PASSED |
| ❌ Failed | $TESTS_FAILED |
| **Total** | **$TOTAL_TESTS** |

## Test Details

| Status | Test | Details |
|--------|------|---------|
EOF

echo -e "$TEST_RESULTS" | while IFS='|' read -r status name details; do
    [ -z "$status" ] && continue
    case "$status" in
        PASS) emoji="✅" ;;
        FAIL) emoji="❌" ;;
        *) emoji="?" ;;
    esac
    echo "| $emoji | $name | $details |" >> "$SUMMARY_FILE"
done

cat >> "$SUMMARY_FILE" << EOF

## Screenshots Captured

EOF

for screenshot in "$SCREENSHOT_DIR"/*.png; do
    [ -f "$screenshot" ] || continue
    filename=$(basename "$screenshot")
    filesize=$(stat -c%s "$screenshot" 2>/dev/null || echo "0")
    echo "- \`$filename\` ($(numfmt --to=iec "$filesize"))" >> "$SUMMARY_FILE"
done

cat >> "$SUMMARY_FILE" << EOF

## VM Configuration

- **Memory:** ${MEMORY}MB
- **CPUs:** $CPUS
- **VRAM:** ${VRAM}MB
- **VirtualBox Version:** $VBOX_VERSION

## Log Files

- VM Configuration: \`logs/vm-config.txt\`
- VBox Log: \`logs/VBox.log\`

EOF

# Generate failure summary if there were failures
if [ "$TESTS_FAILED" -gt 0 ]; then
    cat > "$FAILURE_DIR/SUMMARY.md" << EOF
# VirtualBox Boot Test Failure

**Job:** virtualbox_test  
**Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")  
**Commit:** ${GITHUB_SHA:-local}

## Failed Tests

EOF
    echo -e "$TEST_RESULTS" | grep "^FAIL" | while IFS='|' read -r status name details; do
        [ -z "$name" ] && continue
        echo "- **$name**: $details" >> "$FAILURE_DIR/SUMMARY.md"
    done

    cat >> "$FAILURE_DIR/SUMMARY.md" << EOF

## Likely Causes

Based on the failure pattern, consider these potential issues:

1. **Bootloader misconfiguration** - Check \`isolinux.cfg\` or \`grub.cfg\`
2. **Kernel parameters** - Verify \`boot=live\` and \`live-media-path=/OBSIDIAN\`
3. **initramfs issues** - Check if live-boot hooks are included
4. **Squashfs mount failure** - Verify \`/OBSIDIAN/filesystem.squashfs\` path
5. **EFI vs BIOS mismatch** - Check if ISO supports both boot modes

## Suggested Components to Patch

| Priority | Component | File/Path |
|----------|-----------|-----------|
| 1 | Bootloader | \`iso/isolinux/isolinux.cfg\` |
| 2 | EFI Boot | \`iso/boot/grub/grub.cfg\` |
| 3 | Kernel Params | See APPEND lines in bootloader config |
| 4 | initramfs | \`rootfs/etc/initramfs-tools/\` |
| 5 | Live-boot | \`rootfs/usr/lib/live/boot/\` |
| 6 | Squashfs | \`iso/OBSIDIAN/filesystem.squashfs\` |

## Diagnostic Steps

1. Review screenshots in \`artifacts/virtualbox/screenshots/\`
2. Check VBox.log for VM errors
3. Run locally with VirtualBox GUI for interactive debugging:
   \`\`\`bash
   # Keep VM after test for manual inspection
   VM_NAME=DebugVM ./scripts/virtualbox-boot-test.sh
   \`\`\`
4. Test with QEMU in graphical mode as comparison

## Next Session Action

Copilot should:
1. Review the failure summary above
2. Examine the relevant configuration files
3. Propose targeted fixes based on the failure type
EOF

    # Copy relevant files to failure dir
    cp -r "$SCREENSHOT_DIR" "$FAILURE_DIR/" 2>/dev/null || true
    cp -r "$LOG_DIR" "$FAILURE_DIR/" 2>/dev/null || true
fi

#############################################
# FINAL RESULTS
#############################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Results: $TESTS_PASSED passed"
else
    echo -e "${RED}❌ TESTS FAILED${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
fi

echo ""
echo "📁 Artifacts:"
echo "   Screenshots: $SCREENSHOT_DIR"
echo "   Logs:        $LOG_DIR"
echo "   Summary:     $SUMMARY_FILE"

if [ "$TESTS_FAILED" -gt 0 ]; then
    echo "   Failures:    $FAILURE_DIR/SUMMARY.md"
fi

# Copy to GitHub workspace if running in CI
if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    mkdir -p "$GITHUB_WORKSPACE/artifacts/virtualbox"
    cp -r "$ARTIFACT_DIR"/* "$GITHUB_WORKSPACE/artifacts/virtualbox/" 2>/dev/null || true
    
    if [ "$TESTS_FAILED" -gt 0 ]; then
        mkdir -p "$GITHUB_WORKSPACE/artifacts/failures/virtualbox"
        cp -r "$FAILURE_DIR"/* "$GITHUB_WORKSPACE/artifacts/failures/virtualbox/" 2>/dev/null || true
    fi
fi

# Exit with appropriate code
if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
else
    exit 0
fi
