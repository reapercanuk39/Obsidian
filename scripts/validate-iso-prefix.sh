#!/bin/bash
#############################################
# OBSIDIAN ISO PREFIX/PATH VALIDATOR
# Scans extracted ISO filesystem for forbidden paths
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
ROOTFS_DIR="${1:-$PROJECT_DIR/rootfs}"
VIOLATIONS_FILE="${2:-/tmp/prefix-violations.txt}"
SUMMARY_FILE="${3:-/tmp/prefix-summary.md}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 OBSIDIAN ISO PREFIX/PATH VALIDATOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Scanning: $ROOTFS_DIR"
echo ""

# Initialize
> "$VIOLATIONS_FILE"
VIOLATION_COUNT=0

#############################################
# FORBIDDEN PATHS/STRINGS
#############################################

# Termux legacy paths (must NOT appear)
FORBIDDEN_PATHS=(
    "/data/data/com.termux"
    "/data/data/com.termux/files"
    "/data/data/com.termux/files/usr"
    "/data/data/com.termux/files/home"
    "com.termux"
    "/usr/local/termux"
    "/system/termux"
    "/termux/files"
    "PREFIX=/data"
    "TERMUX_PREFIX"
    "TERMUX_HOME"
    "TERMUX_VERSION"
    "termux-exec"
    "termux-tools"
    "termux-api"
    "termux-am"
    "termux-fix-shebang"
    "pkg install"
    "apt.termux.com"
    "packages.termux.dev"
)

# Android-specific paths (must NOT appear in desktop ISO)
FORBIDDEN_ANDROID=(
    "/system/bin/linker"
    "/system/lib"
    "/vendor/lib"
    "android-ndk"
    "dalvik"
    "/apex/"
)

# Obsidian-specific allowed paths (for reference, not scanned against)
ALLOWED_PATHS=(
    "/obsidian"
    "/usr/obsidian"
    "/etc/obsidian"
    "/opt/obsidian"
    "/var/obsidian"
    "/usr/share/obsidian"
    "/usr/lib/obsidian"
    "/home/obsidian"
)

#############################################
# SCANNING FUNCTIONS
#############################################

scan_file_contents() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if grep -l "$pattern" "$file" 2>/dev/null; then
        echo -e "${RED}✗${NC} Found '$pattern' in: $file"
        echo "CONTENT_VIOLATION|$pattern|$file|$description" >> "$VIOLATIONS_FILE"
        ((VIOLATION_COUNT++)) || true
        return 1
    fi
    return 0
}

scan_path_names() {
    local pattern="$1"
    local description="$2"
    
    while IFS= read -r -d '' file; do
        echo -e "${RED}✗${NC} Path contains '$pattern': $file"
        echo "PATH_VIOLATION|$pattern|$file|$description" >> "$VIOLATIONS_FILE"
        ((VIOLATION_COUNT++)) || true
    done < <(find "$ROOTFS_DIR" -path "*$pattern*" -print0 2>/dev/null || true)
}

scan_symlinks() {
    local pattern="$1"
    local description="$2"
    
    while IFS= read -r -d '' link; do
        target=$(readlink "$link" 2>/dev/null || echo "")
        if [[ "$target" == *"$pattern"* ]]; then
            echo -e "${RED}✗${NC} Symlink '$link' -> '$target' contains forbidden pattern"
            echo "SYMLINK_VIOLATION|$pattern|$link -> $target|$description" >> "$VIOLATIONS_FILE"
            ((VIOLATION_COUNT++)) || true
        fi
    done < <(find "$ROOTFS_DIR" -type l -print0 2>/dev/null || true)
}

#############################################
# MAIN SCAN
#############################################

echo "📋 Phase 1: Scanning directory/file paths..."
echo "─────────────────────────────────────────────"

for pattern in "${FORBIDDEN_PATHS[@]}"; do
    scan_path_names "$pattern" "Forbidden Termux path"
done

for pattern in "${FORBIDDEN_ANDROID[@]}"; do
    scan_path_names "$pattern" "Forbidden Android path"
done

echo ""
echo "📋 Phase 2: Scanning symlink targets..."
echo "─────────────────────────────────────────────"

for pattern in "${FORBIDDEN_PATHS[@]}"; do
    scan_symlinks "$pattern" "Forbidden Termux symlink target"
done

echo ""
echo "📋 Phase 3: Scanning file contents..."
echo "─────────────────────────────────────────────"

# Scan text-based files for forbidden strings
TEXT_EXTENSIONS="sh|py|pl|rb|js|json|yaml|yml|conf|cfg|ini|txt|md|service|desktop|xml|html"

find "$ROOTFS_DIR" -type f \( \
    -name "*.sh" -o -name "*.py" -o -name "*.pl" -o \
    -name "*.rb" -o -name "*.js" -o -name "*.json" -o \
    -name "*.yaml" -o -name "*.yml" -o -name "*.conf" -o \
    -name "*.cfg" -o -name "*.ini" -o -name "*.service" -o \
    -name "*.desktop" -o -name "*.xml" \
\) -size -1M 2>/dev/null | while read -r file; do
    for pattern in "${FORBIDDEN_PATHS[@]}"; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
            echo -e "${RED}✗${NC} Found '$pattern' in: ${file#$ROOTFS_DIR}"
            echo "CONTENT_VIOLATION|$pattern|${file#$ROOTFS_DIR}|Forbidden string in file" >> "$VIOLATIONS_FILE"
            ((VIOLATION_COUNT++)) || true
        fi
    done
done

echo ""
echo "📋 Phase 4: Scanning binary/ELF files for embedded paths..."
echo "─────────────────────────────────────────────"

# Scan ELF binaries for hardcoded paths
find "$ROOTFS_DIR" -type f -executable -size -50M 2>/dev/null | head -1000 | while read -r file; do
    if file "$file" 2>/dev/null | grep -q "ELF"; then
        for pattern in "/data/data/com.termux" "com.termux"; do
            if strings "$file" 2>/dev/null | grep -q "$pattern"; then
                echo -e "${RED}✗${NC} Binary contains '$pattern': ${file#$ROOTFS_DIR}"
                echo "BINARY_VIOLATION|$pattern|${file#$ROOTFS_DIR}|Hardcoded path in binary" >> "$VIOLATIONS_FILE"
                ((VIOLATION_COUNT++)) || true
            fi
        done
    fi
done

echo ""
echo "📋 Phase 5: Validating Obsidian-specific paths..."
echo "─────────────────────────────────────────────"

# Verify expected Obsidian paths exist
EXPECTED_PATHS=(
    "etc/obsidian"
    "usr/share/obsidian"
)

for path in "${EXPECTED_PATHS[@]}"; do
    if [ -d "$ROOTFS_DIR/$path" ] || [ -f "$ROOTFS_DIR/$path" ]; then
        echo -e "${GREEN}✓${NC} Found expected path: /$path"
    else
        echo -e "${YELLOW}⚠${NC} Missing expected path: /$path (optional)"
    fi
done

#############################################
# GENERATE SUMMARY
#############################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count actual violations from file
TOTAL_VIOLATIONS=$(wc -l < "$VIOLATIONS_FILE" 2>/dev/null || echo "0")

# Generate markdown summary
cat > "$SUMMARY_FILE" << EOF
# ISO Prefix/Path Validation Report

**Scan Target:** \`$ROOTFS_DIR\`
**Scan Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Total Violations:** $TOTAL_VIOLATIONS

## Forbidden Patterns Checked

### Termux Legacy Paths
$(printf '- `%s`\n' "${FORBIDDEN_PATHS[@]}")

### Android-Specific Paths  
$(printf '- `%s`\n' "${FORBIDDEN_ANDROID[@]}")

## Violations Found

EOF

if [ "$TOTAL_VIOLATIONS" -gt 0 ]; then
    echo "| Type | Pattern | Location | Description |" >> "$SUMMARY_FILE"
    echo "|------|---------|----------|-------------|" >> "$SUMMARY_FILE"
    while IFS='|' read -r type pattern location description; do
        echo "| $type | \`$pattern\` | \`$location\` | $description |" >> "$SUMMARY_FILE"
    done < "$VIOLATIONS_FILE"
    
    echo -e "${RED}❌ VALIDATION FAILED: $TOTAL_VIOLATIONS violation(s) found${NC}"
    echo ""
    echo "📄 Violations saved to: $VIOLATIONS_FILE"
    echo "📄 Summary saved to: $SUMMARY_FILE"
    echo ""
    echo "Offending files:"
    cut -d'|' -f3 "$VIOLATIONS_FILE" | sort -u | head -20
    exit 1
else
    echo "_No violations found. ISO paths are clean._" >> "$SUMMARY_FILE"
    echo -e "${GREEN}✅ VALIDATION PASSED: No forbidden paths detected${NC}"
    echo ""
    echo "📄 Summary saved to: $SUMMARY_FILE"
    exit 0
fi
