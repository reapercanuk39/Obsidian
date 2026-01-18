#!/bin/bash
#############################################
# OBSIDIAN ISO QEMU BOOT TEST
# Headless boot testing with automated
# smoke tests and console capture
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
ISO_PATH="${1:-$PROJECT_DIR/Obsidian-2.1-FORTRESS.iso}"
TIMEOUT="${BOOT_TIMEOUT:-300}"  # 5 minutes default
MEMORY="${QEMU_MEMORY:-2048}"
CPUS="${QEMU_CPUS:-2}"
TEST_MODE="${TEST_MODE:-full}"  # quick, full, smoke

# Output files
WORK_DIR="/tmp/qemu-boot-test-$$"
CONSOLE_LOG="$WORK_DIR/console.log"
TEST_RESULTS="$WORK_DIR/test-results.txt"
SUMMARY_FILE="$WORK_DIR/SUMMARY.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

#############################################
# CLEANUP HANDLER
#############################################

QEMU_PID=""

cleanup() {
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    
    # Kill QEMU if running
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
    fi
    
    # Don't remove work dir - keep logs for analysis
    echo "Logs saved to: $WORK_DIR"
}
trap cleanup EXIT

#############################################
# HELPER FUNCTIONS
#############################################

log_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📋 $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_test() {
    local status="$1"
    local name="$2"
    local details="${3:-}"
    
    case "$status" in
        PASS)
            echo -e "${GREEN}✓ PASS${NC}: $name"
            echo "PASS|$name|$details" >> "$TEST_RESULTS"
            ((TESTS_PASSED++))
            ;;
        FAIL)
            echo -e "${RED}✗ FAIL${NC}: $name"
            echo "FAIL|$name|$details" >> "$TEST_RESULTS"
            ((TESTS_FAILED++))
            ;;
        SKIP)
            echo -e "${YELLOW}⊘ SKIP${NC}: $name"
            echo "SKIP|$name|$details" >> "$TEST_RESULTS"
            ((TESTS_SKIPPED++))
            ;;
    esac
}

wait_for_pattern() {
    local pattern="$1"
    local timeout="$2"
    local log_file="$3"
    
    local start_time=$(date +%s)
    while true; do
        if grep -q "$pattern" "$log_file" 2>/dev/null; then
            return 0
        fi
        
        local current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge "$timeout" ]; then
            return 1
        fi
        
        sleep 2
    done
}

check_tool() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${RED}❌ Required tool not found: $1${NC}"
        echo "Install with: $2"
        exit 1
    fi
}

#############################################
# PREREQUISITES
#############################################

log_step "Checking Prerequisites"

# Check for QEMU
check_tool "qemu-system-x86_64" "apt install qemu-system-x86"

# Verify ISO exists
if [ ! -f "$ISO_PATH" ]; then
    echo -e "${RED}❌ ISO not found: $ISO_PATH${NC}"
    exit 1
fi

echo "ISO: $ISO_PATH"
echo "Size: $(du -h "$ISO_PATH" | cut -f1)"
echo "Test mode: $TEST_MODE"
echo "Timeout: ${TIMEOUT}s"
echo "Memory: ${MEMORY}MB"
echo "CPUs: $CPUS"

# Create work directory
mkdir -p "$WORK_DIR"
> "$CONSOLE_LOG"
> "$TEST_RESULTS"

#############################################
# START QEMU
#############################################

log_step "Starting QEMU"

# Determine QEMU options based on available features
QEMU_OPTS=(
    -m "$MEMORY"
    -smp "$CPUS"
    -cdrom "$ISO_PATH"
    -boot d
    -nographic
    -serial file:"$CONSOLE_LOG"
    -no-reboot
)

# Check if KVM is available
if [ -r /dev/kvm ]; then
    echo "Using KVM acceleration"
    QEMU_OPTS+=(-enable-kvm)
else
    echo -e "${YELLOW}⚠ KVM not available, using software emulation (slower)${NC}"
fi

# Add networking
QEMU_OPTS+=(
    -net nic,model=virtio
    -net user
)

# Create QEMU monitor socket for control
MONITOR_SOCKET="$WORK_DIR/qemu-monitor.sock"
QEMU_OPTS+=(
    -monitor unix:"$MONITOR_SOCKET",server,nowait
)

# Start QEMU in background
echo "Starting QEMU..."
qemu-system-x86_64 "${QEMU_OPTS[@]}" &
QEMU_PID=$!

echo "QEMU PID: $QEMU_PID"

# Verify QEMU started
sleep 2
if ! kill -0 "$QEMU_PID" 2>/dev/null; then
    echo -e "${RED}❌ QEMU failed to start${NC}"
    cat "$CONSOLE_LOG"
    exit 1
fi

echo "QEMU started successfully"

#############################################
# BOOT TESTS
#############################################

log_step "Running Boot Tests"

# Test 1: BIOS/UEFI initialization
echo "Waiting for boot loader..."
if wait_for_pattern "ISOLINUX\|GRUB\|GNU GRUB\|Booting" 60 "$CONSOLE_LOG"; then
    log_test PASS "Boot loader initialization"
else
    log_test FAIL "Boot loader initialization" "No boot loader detected within 60s"
fi

# Test 2: Kernel loading
echo "Waiting for kernel to load..."
if wait_for_pattern "Linux version\|Booting Linux" 120 "$CONSOLE_LOG"; then
    log_test PASS "Kernel loading"
    
    # Extract kernel version
    KERNEL_VER=$(grep -o "Linux version [^ ]*" "$CONSOLE_LOG" | head -1 || echo "unknown")
    echo "  Detected: $KERNEL_VER"
else
    log_test FAIL "Kernel loading" "Kernel not detected within 120s"
fi

# Test 3: Init system start
echo "Waiting for init system..."
if wait_for_pattern "systemd\|init\|Welcome to\|Starting" 60 "$CONSOLE_LOG"; then
    log_test PASS "Init system start"
else
    log_test FAIL "Init system start" "Init system not detected"
fi

# Test 4: Root filesystem mount
if wait_for_pattern "Mounted\|mount.*root\|filesystem.*mounted\|squashfs" 60 "$CONSOLE_LOG"; then
    log_test PASS "Root filesystem mount"
else
    log_test FAIL "Root filesystem mount" "Filesystem mount not detected"
fi

# Test 5: Systemd target reached (or login prompt)
echo "Waiting for system ready state..."
if wait_for_pattern "login:\|graphical.target\|multi-user.target\|Welcome to Obsidian\|reached target" "$TIMEOUT" "$CONSOLE_LOG"; then
    log_test PASS "System ready state"
else
    log_test FAIL "System ready state" "System did not reach ready state within ${TIMEOUT}s"
fi

#############################################
# EXTENDED TESTS (if system booted)
#############################################

if [ "$TEST_MODE" = "full" ] && [ "$TESTS_FAILED" -eq 0 ]; then
    log_step "Running Extended Tests"
    
    # Check for kernel panic or oops
    if grep -q "Kernel panic\|kernel BUG\|Oops:" "$CONSOLE_LOG"; then
        log_test FAIL "No kernel panic" "Kernel panic or BUG detected"
    else
        log_test PASS "No kernel panic"
    fi
    
    # Check for critical service failures
    if grep -q "Failed to start\|failed to load\|FAILED" "$CONSOLE_LOG"; then
        FAILED_SERVICES=$(grep -o "Failed to start [^.]*" "$CONSOLE_LOG" | head -5 || echo "")
        log_test FAIL "Critical services" "$FAILED_SERVICES"
    else
        log_test PASS "Critical services"
    fi
    
    # Check for filesystem errors
    if grep -q "I/O error\|EXT4-fs error\|SQUASHFS error" "$CONSOLE_LOG"; then
        log_test FAIL "No filesystem errors" "I/O or filesystem errors detected"
    else
        log_test PASS "No filesystem errors"
    fi
    
    # Check for networking initialization
    if grep -q "eth0\|enp\|ens\|network\|NetworkManager\|dhcp" "$CONSOLE_LOG"; then
        log_test PASS "Network initialization"
    else
        log_test SKIP "Network initialization" "No network activity detected"
    fi
    
    # Check for memory issues
    if grep -q "Out of memory\|OOM\|Cannot allocate memory" "$CONSOLE_LOG"; then
        log_test FAIL "No memory issues" "OOM or memory allocation failures detected"
    else
        log_test PASS "No memory issues"
    fi
fi

#############################################
# STOP QEMU
#############################################

log_step "Stopping QEMU"

if [ -S "$MONITOR_SOCKET" ]; then
    echo "quit" | socat - UNIX-CONNECT:"$MONITOR_SOCKET" 2>/dev/null || true
    sleep 2
fi

if kill -0 "$QEMU_PID" 2>/dev/null; then
    kill "$QEMU_PID" 2>/dev/null || true
    wait "$QEMU_PID" 2>/dev/null || true
fi

echo "QEMU stopped"

#############################################
# GENERATE SUMMARY
#############################################

log_step "Generating Test Summary"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

cat > "$SUMMARY_FILE" << EOF
# QEMU Boot Test Summary

**ISO:** \`$(basename "$ISO_PATH")\`  
**Test Mode:** $TEST_MODE  
**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Results

| Status | Count |
|--------|-------|
| ✅ Passed | $TESTS_PASSED |
| ❌ Failed | $TESTS_FAILED |
| ⊘ Skipped | $TESTS_SKIPPED |
| **Total** | **$TOTAL_TESTS** |

## Test Details

| Status | Test | Details |
|--------|------|---------|
EOF

while IFS='|' read -r status name details; do
    case "$status" in
        PASS) emoji="✅" ;;
        FAIL) emoji="❌" ;;
        SKIP) emoji="⊘" ;;
        *) emoji="?" ;;
    esac
    echo "| $emoji | $name | $details |" >> "$SUMMARY_FILE"
done < "$TEST_RESULTS"

# Add console log excerpt if there were failures
if [ "$TESTS_FAILED" -gt 0 ]; then
    cat >> "$SUMMARY_FILE" << EOF

## Console Log (Last 100 lines)

\`\`\`
$(tail -100 "$CONSOLE_LOG")
\`\`\`

## Error Detection

EOF
    
    # Extract potential errors
    if grep -q "error\|Error\|ERROR\|failed\|Failed\|FAILED" "$CONSOLE_LOG"; then
        echo '```' >> "$SUMMARY_FILE"
        grep -i "error\|failed" "$CONSOLE_LOG" | head -20 >> "$SUMMARY_FILE"
        echo '```' >> "$SUMMARY_FILE"
    else
        echo "_No explicit errors found in console log_" >> "$SUMMARY_FILE"
    fi
fi

cat >> "$SUMMARY_FILE" << EOF

## Configuration

- Memory: ${MEMORY}MB
- CPUs: $CPUS
- Timeout: ${TIMEOUT}s
- KVM: $([ -r /dev/kvm ] && echo "enabled" || echo "disabled")
EOF

#############################################
# FINAL RESULTS
#############################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Results: $TESTS_PASSED passed, $TESTS_SKIPPED skipped"
else
    echo -e "${RED}❌ TESTS FAILED${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_SKIPPED skipped"
    echo ""
    echo "Failed tests:"
    grep "^FAIL" "$TEST_RESULTS" | while IFS='|' read -r _ name details; do
        echo "  - $name: $details"
    done
fi

echo ""
echo "📄 Console log: $CONSOLE_LOG"
echo "📄 Summary: $SUMMARY_FILE"
echo "📄 Results: $TEST_RESULTS"

# Copy to standard artifact location if running in CI
if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    mkdir -p "$GITHUB_WORKSPACE/artifacts/qemu-test"
    cp "$CONSOLE_LOG" "$GITHUB_WORKSPACE/artifacts/qemu-test/"
    cp "$SUMMARY_FILE" "$GITHUB_WORKSPACE/artifacts/qemu-test/"
    cp "$TEST_RESULTS" "$GITHUB_WORKSPACE/artifacts/qemu-test/"
fi

# Exit with appropriate code
if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
else
    exit 0
fi
