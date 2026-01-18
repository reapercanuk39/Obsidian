#!/bin/bash
#############################################
# OBSIDIAN ISO PACKAGE CHANGE DETECTOR
# Compares current commit to last successful build
# to determine which components require rebuild
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
LAST_BUILD_SHA="${LAST_BUILD_SHA:-}"
CURRENT_SHA="${CURRENT_SHA:-HEAD}"
OUTPUT_FILE="${OUTPUT_FILE:-/tmp/rebuild-components.txt}"
JSON_OUTPUT="${JSON_OUTPUT:-/tmp/rebuild-components.json}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔍 OBSIDIAN ISO PACKAGE CHANGE DETECTOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$PROJECT_DIR"

#############################################
# COMPONENT DIRECTORIES TO MONITOR
#############################################

declare -A COMPONENTS=(
    ["packages"]="packages/"
    ["rootfs"]="rootfs/"
    ["overlay"]="overlay/"
    ["installer"]="installer/"
    ["bootloader"]="iso/isolinux/ iso/boot/ iso/EFI/"
    ["kernel"]="iso/OBSIDIAN/vmlinuz iso/OBSIDIAN/initrd"
    ["squashfs"]="iso/OBSIDIAN/filesystem.squashfs"
    ["scripts"]="scripts/"
    ["configs"]="configs/ .github/"
    ["docs"]="docs/ README.md CHANGELOG.md"
    ["assets"]="assets/"
)

# Components that trigger full rebuild
FULL_REBUILD_TRIGGERS=(
    "rootfs"
    "packages"
    "kernel"
    "squashfs"
)

#############################################
# DETERMINE COMPARISON BASE
#############################################

get_last_successful_build() {
    # Try to find last successful build from:
    # 1. Environment variable
    # 2. Git tag (last release)
    # 3. GitHub Actions cache marker
    # 4. Fall back to comparing with parent commit
    
    if [ -n "$LAST_BUILD_SHA" ]; then
        echo "$LAST_BUILD_SHA"
        return
    fi
    
    # Try to get last release tag
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -n "$last_tag" ]; then
        echo "$last_tag"
        return
    fi
    
    # Check for .last-successful-build marker file
    if [ -f "$PROJECT_DIR/.last-successful-build" ]; then
        cat "$PROJECT_DIR/.last-successful-build"
        return
    fi
    
    # Fall back to parent commit
    git rev-parse HEAD~1 2>/dev/null || git rev-parse HEAD
}

BASE_SHA=$(get_last_successful_build)
echo "📍 Base commit: $BASE_SHA"
echo "📍 Current commit: $CURRENT_SHA"
echo ""

#############################################
# DETECT CHANGES
#############################################

declare -A CHANGED_COMPONENTS
REBUILD_REQUIRED=false
FULL_REBUILD=false

echo "📋 Analyzing changes..."
echo "─────────────────────────────────────────────"

for component in "${!COMPONENTS[@]}"; do
    paths="${COMPONENTS[$component]}"
    changed=false
    changed_files=()
    
    for path in $paths; do
        if [ -e "$PROJECT_DIR/$path" ] || git ls-tree -r "$CURRENT_SHA" --name-only 2>/dev/null | grep -q "^$path"; then
            # Check if any files in this path changed
            diff_output=$(git diff --name-only "$BASE_SHA" "$CURRENT_SHA" -- "$path" 2>/dev/null || echo "")
            if [ -n "$diff_output" ]; then
                changed=true
                while IFS= read -r file; do
                    changed_files+=("$file")
                done <<< "$diff_output"
            fi
        fi
    done
    
    if [ "$changed" = true ]; then
        CHANGED_COMPONENTS["$component"]="${changed_files[*]}"
        REBUILD_REQUIRED=true
        echo -e "${YELLOW}⚡${NC} $component: CHANGED"
        printf "   └─ %s\n" "${changed_files[@]}" | head -5
        if [ ${#changed_files[@]} -gt 5 ]; then
            echo "   └─ ... and $((${#changed_files[@]} - 5)) more files"
        fi
        
        # Check if this triggers full rebuild
        for trigger in "${FULL_REBUILD_TRIGGERS[@]}"; do
            if [ "$component" = "$trigger" ]; then
                FULL_REBUILD=true
            fi
        done
    else
        echo -e "${GREEN}✓${NC} $component: unchanged"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#############################################
# GENERATE OUTPUT FILES
#############################################

# Plain text output
{
    echo "# Obsidian ISO Rebuild Components"
    echo "# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "# Base: $BASE_SHA"
    echo "# Current: $CURRENT_SHA"
    echo ""
    echo "REBUILD_REQUIRED=$REBUILD_REQUIRED"
    echo "FULL_REBUILD=$FULL_REBUILD"
    echo ""
    echo "CHANGED_COMPONENTS:"
    for component in "${!CHANGED_COMPONENTS[@]}"; do
        echo "  - $component"
    done
} > "$OUTPUT_FILE"

# JSON output for GitHub Actions
{
    echo "{"
    echo "  \"rebuild_required\": $REBUILD_REQUIRED,"
    echo "  \"full_rebuild\": $FULL_REBUILD,"
    echo "  \"base_sha\": \"$BASE_SHA\","
    echo "  \"current_sha\": \"$(git rev-parse "$CURRENT_SHA" 2>/dev/null || echo "$CURRENT_SHA")\","
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
    echo "  \"changed_components\": ["
    first=true
    for component in "${!CHANGED_COMPONENTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        files="${CHANGED_COMPONENTS[$component]}"
        files_json=$(echo "$files" | tr ' ' '\n' | jq -R . | jq -s . 2>/dev/null || echo "[]")
        echo -n "    {\"name\": \"$component\", \"files\": $files_json}"
    done
    echo ""
    echo "  ],"
    echo "  \"rebuild_jobs\": ["
    
    # Determine which CI jobs to run
    jobs=()
    if [ "$FULL_REBUILD" = true ]; then
        jobs=("build_iso" "validate_paths" "qemu_test" "iso_diff" "publish_iso")
    elif [ "$REBUILD_REQUIRED" = true ]; then
        # Selective rebuild based on components
        [[ -v CHANGED_COMPONENTS["bootloader"] ]] && jobs+=("build_iso" "qemu_test")
        [[ -v CHANGED_COMPONENTS["scripts"] ]] && jobs+=("validate_paths")
        [[ -v CHANGED_COMPONENTS["docs"] ]] && jobs+=("update_docs")
        [[ -v CHANGED_COMPONENTS["configs"] ]] && jobs+=("validate_paths")
    fi
    
    first=true
    for job in "${jobs[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo -n ", "
        fi
        echo -n "\"$job\""
    done
    echo ""
    echo "  ]"
    echo "}"
} > "$JSON_OUTPUT"

#############################################
# SUMMARY
#############################################

if [ "$REBUILD_REQUIRED" = true ]; then
    if [ "$FULL_REBUILD" = true ]; then
        echo -e "${RED}🔄 FULL REBUILD REQUIRED${NC}"
        echo ""
        echo "Critical components changed:"
        for trigger in "${FULL_REBUILD_TRIGGERS[@]}"; do
            if [[ -v CHANGED_COMPONENTS["$trigger"] ]]; then
                echo "  - $trigger"
            fi
        done
    else
        echo -e "${YELLOW}⚡ PARTIAL REBUILD REQUIRED${NC}"
        echo ""
        echo "Changed components:"
        for component in "${!CHANGED_COMPONENTS[@]}"; do
            echo "  - $component"
        done
    fi
    
    # Set GitHub Actions output
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        echo "rebuild_required=true" >> "$GITHUB_OUTPUT"
        echo "full_rebuild=$FULL_REBUILD" >> "$GITHUB_OUTPUT"
        {
            echo "changed_components<<EOF"
            for component in "${!CHANGED_COMPONENTS[@]}"; do
                echo "$component"
            done
            echo "EOF"
        } >> "$GITHUB_OUTPUT"
    fi
else
    echo -e "${GREEN}✅ NO REBUILD REQUIRED${NC}"
    echo ""
    echo "No changes detected since last successful build."
    
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        echo "rebuild_required=false" >> "$GITHUB_OUTPUT"
        echo "full_rebuild=false" >> "$GITHUB_OUTPUT"
    fi
fi

echo ""
echo "📄 Output saved to:"
echo "   - $OUTPUT_FILE"
echo "   - $JSON_OUTPUT"

# Exit with appropriate code
if [ "$REBUILD_REQUIRED" = true ]; then
    exit 0  # Changes detected, proceed with build
else
    exit 0  # No changes, but not an error
fi
