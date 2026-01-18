#!/bin/bash
#############################################
# OBSIDIAN ISO DIFF ANALYZER
# Compares old and new ISOs and generates
# a detailed Markdown report
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Arguments
OLD_ISO="${1:-}"
NEW_ISO="${2:-}"
OUTPUT_REPORT="${3:-/tmp/iso-diff-report.md}"

# Work directories
WORK_DIR="/tmp/iso-diff-$$"
OLD_MOUNT="$WORK_DIR/old-iso"
NEW_MOUNT="$WORK_DIR/new-iso"
OLD_SQUASH="$WORK_DIR/old-squashfs"
NEW_SQUASH="$WORK_DIR/new-squashfs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#############################################
# CLEANUP HANDLER
#############################################

cleanup() {
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    
    # Unmount ISO filesystems
    for mount_point in "$OLD_MOUNT" "$NEW_MOUNT" "$OLD_SQUASH" "$NEW_SQUASH"; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            umount "$mount_point" 2>/dev/null || true
        fi
    done
    
    # Remove work directory
    if [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

#############################################
# USAGE
#############################################

usage() {
    echo "Usage: $0 <old-iso> <new-iso> [output-report.md]"
    echo ""
    echo "Compare two Obsidian ISO files and generate a diff report."
    echo ""
    echo "Arguments:"
    echo "  old-iso         Path to the previous/old ISO file"
    echo "  new-iso         Path to the new/current ISO file"
    echo "  output-report   Path for the Markdown report (default: /tmp/iso-diff-report.md)"
    exit 1
}

if [ -z "$OLD_ISO" ] || [ -z "$NEW_ISO" ]; then
    usage
fi

if [ ! -f "$OLD_ISO" ]; then
    echo -e "${RED}❌ Old ISO not found: $OLD_ISO${NC}"
    exit 1
fi

if [ ! -f "$NEW_ISO" ]; then
    echo -e "${RED}❌ New ISO not found: $NEW_ISO${NC}"
    exit 1
fi

#############################################
# SETUP
#############################################

echo "🔍 OBSIDIAN ISO DIFF ANALYZER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Old ISO: $OLD_ISO"
echo "New ISO: $NEW_ISO"
echo "Report:  $OUTPUT_REPORT"
echo ""

# Create work directories
mkdir -p "$OLD_MOUNT" "$NEW_MOUNT" "$OLD_SQUASH" "$NEW_SQUASH"

#############################################
# EXTRACT/MOUNT ISOS
#############################################

echo -e "${BLUE}📦 Extracting ISOs...${NC}"

extract_iso() {
    local iso_path="$1"
    local mount_point="$2"
    local squash_mount="$3"
    local label="$4"
    
    echo "  Extracting $label ISO..."
    
    # Try to mount ISO
    if mount -o loop,ro "$iso_path" "$mount_point" 2>/dev/null; then
        echo "    ✓ Mounted ISO"
    else
        # Fall back to xorriso extraction
        echo "    Using xorriso extraction..."
        xorriso -osirrox on -indev "$iso_path" -extract / "$mount_point" 2>/dev/null
    fi
    
    # Extract squashfs if present
    local squashfs_file=""
    for possible_path in "$mount_point/OBSIDIAN/filesystem.squashfs" \
                         "$mount_point/live/filesystem.squashfs" \
                         "$mount_point/casper/filesystem.squashfs"; do
        if [ -f "$possible_path" ]; then
            squashfs_file="$possible_path"
            break
        fi
    done
    
    if [ -n "$squashfs_file" ]; then
        echo "    Extracting squashfs..."
        unsquashfs -f -d "$squash_mount" "$squashfs_file" >/dev/null 2>&1 || {
            echo "    ⚠ Could not extract squashfs"
        }
    else
        echo "    ⚠ No squashfs found in ISO"
    fi
}

extract_iso "$OLD_ISO" "$OLD_MOUNT" "$OLD_SQUASH" "old"
extract_iso "$NEW_ISO" "$NEW_MOUNT" "$NEW_SQUASH" "new"

#############################################
# ANALYSIS FUNCTIONS
#############################################

# Get ISO metadata
get_iso_size() {
    stat -c%s "$1" 2>/dev/null || echo "0"
}

# Compare file lists
compare_files() {
    local old_dir="$1"
    local new_dir="$2"
    local prefix="$3"
    
    # Generate file lists
    find "$old_dir" -type f -printf "%P\n" 2>/dev/null | sort > "$WORK_DIR/old-files.txt"
    find "$new_dir" -type f -printf "%P\n" 2>/dev/null | sort > "$WORK_DIR/new-files.txt"
    
    # Find additions, removals, and common files
    comm -23 "$WORK_DIR/new-files.txt" "$WORK_DIR/old-files.txt" > "$WORK_DIR/added-files.txt"
    comm -13 "$WORK_DIR/new-files.txt" "$WORK_DIR/old-files.txt" > "$WORK_DIR/removed-files.txt"
    comm -12 "$WORK_DIR/new-files.txt" "$WORK_DIR/old-files.txt" > "$WORK_DIR/common-files.txt"
}

# Calculate size difference
size_diff() {
    local old_size=$1
    local new_size=$2
    local diff=$((new_size - old_size))
    
    if [ $diff -gt 0 ]; then
        echo "+$(numfmt --to=iec $diff)"
    elif [ $diff -lt 0 ]; then
        echo "-$(numfmt --to=iec ${diff#-})"
    else
        echo "0"
    fi
}

# Compare checksums of common files
find_modified_files() {
    local old_dir="$1"
    local new_dir="$2"
    
    while IFS= read -r file; do
        if [ -f "$old_dir/$file" ] && [ -f "$new_dir/$file" ]; then
            old_hash=$(md5sum "$old_dir/$file" 2>/dev/null | cut -d' ' -f1 || echo "none")
            new_hash=$(md5sum "$new_dir/$file" 2>/dev/null | cut -d' ' -f1 || echo "none")
            
            if [ "$old_hash" != "$new_hash" ]; then
                echo "$file"
            fi
        fi
    done < "$WORK_DIR/common-files.txt" | head -500  # Limit to 500 to avoid huge output
}

#############################################
# RUN ANALYSIS
#############################################

echo -e "${BLUE}📊 Analyzing differences...${NC}"

# ISO-level comparison
OLD_ISO_SIZE=$(get_iso_size "$OLD_ISO")
NEW_ISO_SIZE=$(get_iso_size "$NEW_ISO")
ISO_SIZE_DIFF=$(size_diff "$OLD_ISO_SIZE" "$NEW_ISO_SIZE")

echo "  ISO size: $(numfmt --to=iec $OLD_ISO_SIZE) → $(numfmt --to=iec $NEW_ISO_SIZE) ($ISO_SIZE_DIFF)"

# Compare ISO contents
echo "  Comparing ISO contents..."
compare_files "$OLD_MOUNT" "$NEW_MOUNT" "iso"
ISO_ADDED=$(wc -l < "$WORK_DIR/added-files.txt")
ISO_REMOVED=$(wc -l < "$WORK_DIR/removed-files.txt")
mv "$WORK_DIR/added-files.txt" "$WORK_DIR/iso-added.txt"
mv "$WORK_DIR/removed-files.txt" "$WORK_DIR/iso-removed.txt"

# Compare squashfs contents if available
SQUASH_ADDED=0
SQUASH_REMOVED=0
if [ -d "$OLD_SQUASH" ] && [ "$(ls -A "$OLD_SQUASH" 2>/dev/null)" ]; then
    echo "  Comparing filesystem contents..."
    compare_files "$OLD_SQUASH" "$NEW_SQUASH" "squashfs"
    SQUASH_ADDED=$(wc -l < "$WORK_DIR/added-files.txt")
    SQUASH_REMOVED=$(wc -l < "$WORK_DIR/removed-files.txt")
    mv "$WORK_DIR/added-files.txt" "$WORK_DIR/squash-added.txt"
    mv "$WORK_DIR/removed-files.txt" "$WORK_DIR/squash-removed.txt"
    mv "$WORK_DIR/common-files.txt" "$WORK_DIR/squash-common.txt"
    
    echo "  Finding modified files..."
    find_modified_files "$OLD_SQUASH" "$NEW_SQUASH" > "$WORK_DIR/squash-modified.txt"
    SQUASH_MODIFIED=$(wc -l < "$WORK_DIR/squash-modified.txt")
fi

# Compare kernel and initrd
echo "  Comparing boot components..."

compare_boot_file() {
    local name="$1"
    local old_file="$2"
    local new_file="$3"
    
    local old_size=0 new_size=0 old_hash="none" new_hash="none"
    
    [ -f "$old_file" ] && old_size=$(stat -c%s "$old_file") && old_hash=$(md5sum "$old_file" | cut -d' ' -f1)
    [ -f "$new_file" ] && new_size=$(stat -c%s "$new_file") && new_hash=$(md5sum "$new_file" | cut -d' ' -f1)
    
    if [ "$old_hash" = "$new_hash" ]; then
        echo "unchanged"
    else
        echo "modified|$(numfmt --to=iec $old_size)|$(numfmt --to=iec $new_size)"
    fi
}

KERNEL_STATUS=$(compare_boot_file "kernel" "$OLD_MOUNT/OBSIDIAN/vmlinuz" "$NEW_MOUNT/OBSIDIAN/vmlinuz")
INITRD_STATUS=$(compare_boot_file "initrd" "$OLD_MOUNT/OBSIDIAN/initrd" "$NEW_MOUNT/OBSIDIAN/initrd")
SQUASHFS_STATUS=$(compare_boot_file "squashfs" "$OLD_MOUNT/OBSIDIAN/filesystem.squashfs" "$NEW_MOUNT/OBSIDIAN/filesystem.squashfs")

# Package analysis (if dpkg available in squashfs)
PACKAGES_ADDED=""
PACKAGES_REMOVED=""
PACKAGES_UPDATED=""

if [ -f "$OLD_SQUASH/var/lib/dpkg/status" ] && [ -f "$NEW_SQUASH/var/lib/dpkg/status" ]; then
    echo "  Analyzing package changes..."
    
    grep "^Package:" "$OLD_SQUASH/var/lib/dpkg/status" | cut -d' ' -f2 | sort > "$WORK_DIR/old-packages.txt"
    grep "^Package:" "$NEW_SQUASH/var/lib/dpkg/status" | cut -d' ' -f2 | sort > "$WORK_DIR/new-packages.txt"
    
    comm -23 "$WORK_DIR/new-packages.txt" "$WORK_DIR/old-packages.txt" > "$WORK_DIR/packages-added.txt"
    comm -13 "$WORK_DIR/new-packages.txt" "$WORK_DIR/old-packages.txt" > "$WORK_DIR/packages-removed.txt"
    
    PACKAGES_ADDED_COUNT=$(wc -l < "$WORK_DIR/packages-added.txt")
    PACKAGES_REMOVED_COUNT=$(wc -l < "$WORK_DIR/packages-removed.txt")
fi

#############################################
# GENERATE MARKDOWN REPORT
#############################################

echo -e "${BLUE}📝 Generating report...${NC}"

cat > "$OUTPUT_REPORT" << EOF
# Obsidian ISO Diff Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Summary

| Metric | Old | New | Change |
|--------|-----|-----|--------|
| **ISO Size** | $(numfmt --to=iec $OLD_ISO_SIZE) | $(numfmt --to=iec $NEW_ISO_SIZE) | $ISO_SIZE_DIFF |
| **Files in ISO** | - | - | +$ISO_ADDED / -$ISO_REMOVED |
| **Files in Filesystem** | - | - | +$SQUASH_ADDED / -$SQUASH_REMOVED |

## Boot Components

| Component | Status | Details |
|-----------|--------|---------|
| **Kernel (vmlinuz)** | $(echo "$KERNEL_STATUS" | cut -d'|' -f1) | $([ "$KERNEL_STATUS" != "unchanged" ] && echo "$(echo $KERNEL_STATUS | cut -d'|' -f2) → $(echo $KERNEL_STATUS | cut -d'|' -f3)" || echo "No changes") |
| **Initrd** | $(echo "$INITRD_STATUS" | cut -d'|' -f1) | $([ "$INITRD_STATUS" != "unchanged" ] && echo "$(echo $INITRD_STATUS | cut -d'|' -f2) → $(echo $INITRD_STATUS | cut -d'|' -f3)" || echo "No changes") |
| **SquashFS** | $(echo "$SQUASHFS_STATUS" | cut -d'|' -f1) | $([ "$SQUASHFS_STATUS" != "unchanged" ] && echo "$(echo $SQUASHFS_STATUS | cut -d'|' -f2) → $(echo $SQUASHFS_STATUS | cut -d'|' -f3)" || echo "No changes") |

## ISO Structure Changes

### Files Added to ISO ($ISO_ADDED)
EOF

if [ -s "$WORK_DIR/iso-added.txt" ]; then
    echo '```' >> "$OUTPUT_REPORT"
    head -50 "$WORK_DIR/iso-added.txt" >> "$OUTPUT_REPORT"
    [ $(wc -l < "$WORK_DIR/iso-added.txt") -gt 50 ] && echo "... and $((ISO_ADDED - 50)) more" >> "$OUTPUT_REPORT"
    echo '```' >> "$OUTPUT_REPORT"
else
    echo "_No files added_" >> "$OUTPUT_REPORT"
fi

cat >> "$OUTPUT_REPORT" << EOF

### Files Removed from ISO ($ISO_REMOVED)
EOF

if [ -s "$WORK_DIR/iso-removed.txt" ]; then
    echo '```' >> "$OUTPUT_REPORT"
    head -50 "$WORK_DIR/iso-removed.txt" >> "$OUTPUT_REPORT"
    [ $(wc -l < "$WORK_DIR/iso-removed.txt") -gt 50 ] && echo "... and $((ISO_REMOVED - 50)) more" >> "$OUTPUT_REPORT"
    echo '```' >> "$OUTPUT_REPORT"
else
    echo "_No files removed_" >> "$OUTPUT_REPORT"
fi

# Filesystem changes
if [ -f "$WORK_DIR/squash-added.txt" ]; then
    cat >> "$OUTPUT_REPORT" << EOF

## Filesystem Changes

### Files Added ($SQUASH_ADDED)
EOF
    if [ -s "$WORK_DIR/squash-added.txt" ]; then
        echo '```' >> "$OUTPUT_REPORT"
        head -100 "$WORK_DIR/squash-added.txt" >> "$OUTPUT_REPORT"
        [ "$SQUASH_ADDED" -gt 100 ] && echo "... and $((SQUASH_ADDED - 100)) more" >> "$OUTPUT_REPORT"
        echo '```' >> "$OUTPUT_REPORT"
    else
        echo "_No files added_" >> "$OUTPUT_REPORT"
    fi
    
    cat >> "$OUTPUT_REPORT" << EOF

### Files Removed ($SQUASH_REMOVED)
EOF
    if [ -s "$WORK_DIR/squash-removed.txt" ]; then
        echo '```' >> "$OUTPUT_REPORT"
        head -100 "$WORK_DIR/squash-removed.txt" >> "$OUTPUT_REPORT"
        [ "$SQUASH_REMOVED" -gt 100 ] && echo "... and $((SQUASH_REMOVED - 100)) more" >> "$OUTPUT_REPORT"
        echo '```' >> "$OUTPUT_REPORT"
    else
        echo "_No files removed_" >> "$OUTPUT_REPORT"
    fi
    
    cat >> "$OUTPUT_REPORT" << EOF

### Files Modified ($SQUASH_MODIFIED)
EOF
    if [ -s "$WORK_DIR/squash-modified.txt" ]; then
        echo '```' >> "$OUTPUT_REPORT"
        head -100 "$WORK_DIR/squash-modified.txt" >> "$OUTPUT_REPORT"
        [ "$SQUASH_MODIFIED" -gt 100 ] && echo "... and $((SQUASH_MODIFIED - 100)) more" >> "$OUTPUT_REPORT"
        echo '```' >> "$OUTPUT_REPORT"
    else
        echo "_No files modified_" >> "$OUTPUT_REPORT"
    fi
fi

# Package changes
if [ -f "$WORK_DIR/packages-added.txt" ]; then
    cat >> "$OUTPUT_REPORT" << EOF

## Package Changes

### Packages Added ($PACKAGES_ADDED_COUNT)
EOF
    if [ -s "$WORK_DIR/packages-added.txt" ]; then
        echo '```' >> "$OUTPUT_REPORT"
        cat "$WORK_DIR/packages-added.txt" >> "$OUTPUT_REPORT"
        echo '```' >> "$OUTPUT_REPORT"
    else
        echo "_No packages added_" >> "$OUTPUT_REPORT"
    fi
    
    cat >> "$OUTPUT_REPORT" << EOF

### Packages Removed ($PACKAGES_REMOVED_COUNT)
EOF
    if [ -s "$WORK_DIR/packages-removed.txt" ]; then
        echo '```' >> "$OUTPUT_REPORT"
        cat "$WORK_DIR/packages-removed.txt" >> "$OUTPUT_REPORT"
        echo '```' >> "$OUTPUT_REPORT"
    else
        echo "_No packages removed_" >> "$OUTPUT_REPORT"
    fi
fi

# Footer
cat >> "$OUTPUT_REPORT" << EOF

---

## Files Compared

- **Old ISO:** \`$(basename "$OLD_ISO")\`
  - Size: $(numfmt --to=iec $OLD_ISO_SIZE)
  - SHA256: \`$(sha256sum "$OLD_ISO" | cut -d' ' -f1)\`

- **New ISO:** \`$(basename "$NEW_ISO")\`
  - Size: $(numfmt --to=iec $NEW_ISO_SIZE)
  - SHA256: \`$(sha256sum "$NEW_ISO" | cut -d' ' -f1)\`
EOF

#############################################
# SUMMARY
#############################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ DIFF ANALYSIS COMPLETE${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo "   ISO size change: $ISO_SIZE_DIFF"
echo "   ISO files: +$ISO_ADDED added, -$ISO_REMOVED removed"
if [ -f "$WORK_DIR/squash-added.txt" ]; then
    echo "   Filesystem: +$SQUASH_ADDED added, -$SQUASH_REMOVED removed, ~$SQUASH_MODIFIED modified"
fi
if [ -f "$WORK_DIR/packages-added.txt" ]; then
    echo "   Packages: +$PACKAGES_ADDED_COUNT added, -$PACKAGES_REMOVED_COUNT removed"
fi
echo ""
echo "📄 Report saved to: $OUTPUT_REPORT"
