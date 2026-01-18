#!/bin/bash
#############################################
# OBSIDIAN OS ISO BUILD SCRIPT
# Full automated ISO assembly pipeline
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Build Configuration
BUILD_ARCH="${BUILD_ARCH:-x86_64}"
BUILD_DATE="$(date -u +"%Y%m%d")"
BUILD_ID="${BUILD_ID:-$(git rev-parse --short HEAD 2>/dev/null || echo 'dev')}"
VERSION="${VERSION:-2.1}"
CODENAME="${CODENAME:-FORTRESS}"

# Paths
ROOTFS_DIR="$PROJECT_DIR/rootfs"
ISO_DIR="$PROJECT_DIR/iso"
OVERLAY_DIR="$PROJECT_DIR/overlay"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_DIR}"
WORK_DIR="/tmp/obsidian-build-$$"
SQUASHFS_DIR="$ISO_DIR/OBSIDIAN"

# Output files
ISO_NAME="Obsidian-${VERSION}-${CODENAME}.iso"
ISO_PATH="$OUTPUT_DIR/$ISO_NAME"

# ISO metadata
VOLUME_ID="OBSIDIAN"
APP_ID="Obsidian OS V${VERSION} ${CODENAME}"
PUBLISHER="Obsidian OS Project"
PREPARER="Obsidian Build System"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Cleanup handler
cleanup() {
    echo ""
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    
    # Unmount any mounted filesystems
    if mountpoint -q "$WORK_DIR/squashfs-mount" 2>/dev/null; then
        umount "$WORK_DIR/squashfs-mount" 2>/dev/null || true
    fi
    
    # Remove work directory
    if [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
    fi
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

check_tool() {
    if ! command -v "$1" &>/dev/null; then
        log_error "Required tool not found: $1"
        echo "Install with: $2"
        exit 1
    fi
}

#############################################
# PREREQUISITES CHECK
#############################################

log_step "Checking Prerequisites"

# Required tools
check_tool "xorriso" "apt install xorriso"
check_tool "mksquashfs" "apt install squashfs-tools"
check_tool "unsquashfs" "apt install squashfs-tools"
check_tool "sha256sum" "apt install coreutils"

# Optional but recommended
command -v grub-mkimage &>/dev/null || log_warning "grub-mkimage not found (EFI support may be limited)"

# Check for root/fakeroot for squashfs
if [ "$(id -u)" -ne 0 ] && ! command -v fakeroot &>/dev/null; then
    log_warning "Not running as root and fakeroot not available"
    log_warning "File ownership in squashfs may be incorrect"
fi

# Validate source directories
if [ ! -d "$ROOTFS_DIR" ]; then
    log_error "Root filesystem not found: $ROOTFS_DIR"
    exit 1
fi

if [ ! -d "$ISO_DIR" ]; then
    log_error "ISO directory not found: $ISO_DIR"
    exit 1
fi

log_success "Prerequisites check passed"

#############################################
# PRINT BUILD INFORMATION
#############################################

echo ""
echo "🔥 OBSIDIAN OS BUILD SYSTEM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Version:     ${VERSION}-${CODENAME}"
echo "  Build ID:    ${BUILD_ID}"
echo "  Build Date:  ${BUILD_DATE}"
echo "  Architecture: ${BUILD_ARCH}"
echo "  Output:      ${ISO_PATH}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#############################################
# PREPARE WORK DIRECTORY
#############################################

log_step "Preparing Build Environment"

mkdir -p "$WORK_DIR"/{rootfs-work,squashfs-mount}
mkdir -p "$OUTPUT_DIR"
mkdir -p "$SQUASHFS_DIR"

log_success "Work directory created: $WORK_DIR"

#############################################
# ASSEMBLE ROOT FILESYSTEM
#############################################

log_step "Assembling Root Filesystem"

ROOTFS_WORK="$WORK_DIR/rootfs-work"

# Copy base rootfs
log_info "Copying base root filesystem..."
rsync -a --info=progress2 "$ROOTFS_DIR/" "$ROOTFS_WORK/"

# Apply overlays if they exist
if [ -d "$OVERLAY_DIR" ]; then
    log_info "Applying overlay customizations..."
    rsync -a --info=progress2 "$OVERLAY_DIR/" "$ROOTFS_WORK/"
fi

# Set build metadata in the filesystem
log_info "Setting build metadata..."
mkdir -p "$ROOTFS_WORK/etc/obsidian"
cat > "$ROOTFS_WORK/etc/obsidian/build-info" << EOF
OBSIDIAN_VERSION=${VERSION}
OBSIDIAN_CODENAME=${CODENAME}
OBSIDIAN_BUILD_ID=${BUILD_ID}
OBSIDIAN_BUILD_DATE=${BUILD_DATE}
OBSIDIAN_ARCH=${BUILD_ARCH}
EOF

# Set os-release
cat > "$ROOTFS_WORK/etc/os-release" << EOF
PRETTY_NAME="Obsidian OS ${VERSION} (${CODENAME})"
NAME="Obsidian OS"
VERSION_ID="${VERSION}"
VERSION="${VERSION} (${CODENAME})"
VERSION_CODENAME=${CODENAME,,}
ID=obsidian
ID_LIKE=debian
HOME_URL="https://github.com/obsidian-os"
BUG_REPORT_URL="https://github.com/obsidian-os/issues"
EOF

# Clean up unnecessary files
log_info "Cleaning up temporary files..."
find "$ROOTFS_WORK" -name "*.pyc" -delete 2>/dev/null || true
find "$ROOTFS_WORK" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$ROOTFS_WORK" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
rm -rf "$ROOTFS_WORK/tmp/"* 2>/dev/null || true
rm -rf "$ROOTFS_WORK/var/cache/apt/archives/"*.deb 2>/dev/null || true
rm -rf "$ROOTFS_WORK/var/log/"*.log 2>/dev/null || true

log_success "Root filesystem assembled"

#############################################
# RUN PATH VALIDATION
#############################################

log_step "Validating Filesystem Paths"

if [ -x "$SCRIPT_DIR/validate-iso-prefix.sh" ]; then
    if ! "$SCRIPT_DIR/validate-iso-prefix.sh" "$ROOTFS_WORK"; then
        log_error "Path validation failed! Aborting build."
        exit 1
    fi
else
    log_warning "Path validator not found, skipping validation"
fi

log_success "Path validation passed"

#############################################
# GENERATE SQUASHFS
#############################################

log_step "Generating SquashFS Filesystem"

SQUASHFS_FILE="$SQUASHFS_DIR/filesystem.squashfs"
SQUASHFS_SIZE_FILE="$SQUASHFS_DIR/filesystem.size"

# Remove old squashfs
rm -f "$SQUASHFS_FILE" "$SQUASHFS_SIZE_FILE"

# Calculate filesystem size
ROOTFS_SIZE=$(du -sx --block-size=1 "$ROOTFS_WORK" | cut -f1)
echo "$ROOTFS_SIZE" > "$SQUASHFS_SIZE_FILE"
log_info "Root filesystem size: $(numfmt --to=iec $ROOTFS_SIZE)"

# Compression options based on architecture
case "$BUILD_ARCH" in
    x86_64|amd64)
        COMP_OPTS="-comp xz -Xbcj x86 -b 1M -Xdict-size 100%"
        ;;
    aarch64|arm64)
        COMP_OPTS="-comp xz -b 1M -Xdict-size 100%"
        ;;
    *)
        COMP_OPTS="-comp xz -b 1M"
        ;;
esac

log_info "Creating squashfs with XZ compression..."

# Use fakeroot if available and not root
if [ "$(id -u)" -ne 0 ] && command -v fakeroot &>/dev/null; then
    fakeroot mksquashfs "$ROOTFS_WORK" "$SQUASHFS_FILE" \
        $COMP_OPTS \
        -wildcards \
        -e "boot/vmlinuz*" "boot/initrd*" \
        -noappend \
        -progress
else
    mksquashfs "$ROOTFS_WORK" "$SQUASHFS_FILE" \
        $COMP_OPTS \
        -wildcards \
        -e "boot/vmlinuz*" "boot/initrd*" \
        -noappend \
        -progress
fi

SQUASHFS_SIZE=$(stat -c%s "$SQUASHFS_FILE")
log_success "SquashFS created: $(numfmt --to=iec $SQUASHFS_SIZE)"

#############################################
# COPY KERNEL AND INITRD
#############################################

log_step "Setting Up Boot Files"

# Copy kernel
if [ -f "$ROOTFS_WORK/vmlinuz" ]; then
    cp "$ROOTFS_WORK/vmlinuz" "$SQUASHFS_DIR/vmlinuz"
elif [ -f "$ROOTFS_WORK/boot/vmlinuz" ]; then
    cp "$ROOTFS_WORK/boot/vmlinuz" "$SQUASHFS_DIR/vmlinuz"
elif [ -f "$SQUASHFS_DIR/vmlinuz" ]; then
    log_info "Using existing kernel"
else
    log_error "Kernel not found!"
    exit 1
fi

# Copy initrd
if [ -f "$ROOTFS_WORK/initrd.img" ]; then
    cp "$ROOTFS_WORK/initrd.img" "$SQUASHFS_DIR/initrd"
elif [ -f "$ROOTFS_WORK/boot/initrd.img" ]; then
    cp "$ROOTFS_WORK/boot/initrd.img" "$SQUASHFS_DIR/initrd"
elif [ -f "$SQUASHFS_DIR/initrd" ]; then
    log_info "Using existing initrd"
else
    log_error "Initrd not found!"
    exit 1
fi

log_success "Boot files configured"

#############################################
# CONFIGURE BOOTLOADER
#############################################

log_step "Configuring Bootloader"

# Ensure isolinux directory exists
mkdir -p "$ISO_DIR/isolinux"

# Create/update isolinux.cfg
cat > "$ISO_DIR/isolinux/isolinux.cfg" << 'EOF'
DEFAULT obsidian
TIMEOUT 50
PROMPT 0

UI vesamenu.c32
MENU TITLE Obsidian OS Boot Menu
MENU BACKGROUND splash.png
MENU COLOR border       30;44   #40ffffff #00000000 std
MENU COLOR title        1;36;44 #ff00ffff #00000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #00000000 std
MENU COLOR help         37;40   #c0ffffff #00000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std

LABEL obsidian
    MENU LABEL ^Obsidian OS (Live)
    MENU DEFAULT
    KERNEL /OBSIDIAN/vmlinuz
    APPEND initrd=/OBSIDIAN/initrd boot=live components quiet splash

LABEL obsidian-safe
    MENU LABEL Obsidian OS (^Safe Mode)
    KERNEL /OBSIDIAN/vmlinuz
    APPEND initrd=/OBSIDIAN/initrd boot=live components nomodeset

LABEL obsidian-forensic
    MENU LABEL Obsidian OS (^Forensic Mode)
    KERNEL /OBSIDIAN/vmlinuz
    APPEND initrd=/OBSIDIAN/initrd boot=live components toram noswap

LABEL memtest
    MENU LABEL ^Memory Test
    KERNEL /boot/memtest86+.bin
EOF

# Create GRUB config for EFI
mkdir -p "$ISO_DIR/boot/grub"
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=5

insmod all_video
insmod gfxterm
insmod png

set gfxmode=auto
terminal_output gfxterm

menuentry "Obsidian OS (Live)" --class obsidian --class os {
    linux /OBSIDIAN/vmlinuz boot=live components quiet splash
    initrd /OBSIDIAN/initrd
}

menuentry "Obsidian OS (Safe Mode)" --class obsidian --class os {
    linux /OBSIDIAN/vmlinuz boot=live components nomodeset
    initrd /OBSIDIAN/initrd
}

menuentry "Obsidian OS (Forensic Mode)" --class obsidian --class os {
    linux /OBSIDIAN/vmlinuz boot=live components toram noswap
    initrd /OBSIDIAN/initrd
}

menuentry "System Restart" --class restart {
    reboot
}

menuentry "System Shutdown" --class shutdown {
    halt
}
EOF

log_success "Bootloader configured"

#############################################
# BUILD ISO
#############################################

log_step "Building ISO Image"

# Check for required ISOLINUX files
ISOLINUX_BIN="/usr/lib/ISOLINUX/isolinux.bin"
ISOHDPFX="/usr/lib/ISOLINUX/isohdpfx.bin"

if [ ! -f "$ISOLINUX_BIN" ]; then
    # Try alternative path
    ISOLINUX_BIN="/usr/lib/syslinux/bios/isolinux.bin"
fi

if [ ! -f "$ISOHDPFX" ]; then
    ISOHDPFX="/usr/lib/syslinux/bios/isohdpfx.bin"
fi

# Copy isolinux binaries if needed
if [ -f "$ISOLINUX_BIN" ] && [ ! -f "$ISO_DIR/isolinux/isolinux.bin" ]; then
    cp "$ISOLINUX_BIN" "$ISO_DIR/isolinux/"
fi

# Copy required syslinux modules
for module in ldlinux.c32 libcom32.c32 libutil.c32 vesamenu.c32 libmenu.c32; do
    for search_path in /usr/lib/syslinux/modules/bios /usr/lib/SYSLINUX; do
        if [ -f "$search_path/$module" ] && [ ! -f "$ISO_DIR/isolinux/$module" ]; then
            cp "$search_path/$module" "$ISO_DIR/isolinux/"
            break
        fi
    done
done

log_info "Building hybrid ISO with xorriso..."

cd "$OUTPUT_DIR"

# Build the ISO
XORRISO_ARGS=(
    -as mkisofs
    -iso-level 3
    -full-iso9660-filenames
    -joliet
    -joliet-long
    -rational-rock
    -volid "$VOLUME_ID"
    -appid "$APP_ID"
    -publisher "$PUBLISHER"
    -preparer "$PREPARER"
)

# BIOS boot (ISOLINUX)
if [ -f "$ISO_DIR/isolinux/isolinux.bin" ]; then
    XORRISO_ARGS+=(
        -eltorito-boot isolinux/isolinux.bin
        -eltorito-catalog isolinux/boot.cat
        -no-emul-boot
        -boot-load-size 4
        -boot-info-table
    )
    
    if [ -f "$ISOHDPFX" ]; then
        XORRISO_ARGS+=(-isohybrid-mbr "$ISOHDPFX")
    fi
fi

# EFI boot
if [ -f "$ISO_DIR/boot/grub/efi.img" ]; then
    XORRISO_ARGS+=(
        -eltorito-alt-boot
        -e boot/grub/efi.img
        -no-emul-boot
        -isohybrid-gpt-basdat
    )
fi

XORRISO_ARGS+=(
    -output "$ISO_NAME"
    "$ISO_DIR"
)

xorriso "${XORRISO_ARGS[@]}"

log_success "ISO created: $ISO_NAME"

#############################################
# GENERATE CHECKSUMS
#############################################

log_step "Generating Checksums"

cd "$OUTPUT_DIR"

sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256"
md5sum "$ISO_NAME" > "${ISO_NAME}.md5"

log_success "Checksums generated"

#############################################
# VERIFY ISO
#############################################

log_step "Verifying ISO"

# Verify ISO structure
log_info "Checking ISO structure..."
xorriso -indev "$ISO_PATH" -find / -maxdepth 1 2>/dev/null | head -20

# Verify squashfs inside ISO
log_info "Verifying embedded squashfs..."
xorriso -indev "$ISO_PATH" -extract /OBSIDIAN/filesystem.squashfs /tmp/verify-squashfs-$$ 2>/dev/null
if unsquashfs -s /tmp/verify-squashfs-$$ >/dev/null 2>&1; then
    log_success "Embedded squashfs is valid"
else
    log_warning "Could not verify embedded squashfs"
fi
rm -f /tmp/verify-squashfs-$$

#############################################
# BUILD SUMMARY
#############################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 BUILD COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📀 ISO:      $ISO_PATH"
echo "📊 Size:     $(du -h "$ISO_PATH" | cut -f1)"
echo "🔐 SHA256:   $(cat "${ISO_PATH}.sha256" | cut -d' ' -f1)"
echo "🔐 MD5:      $(cat "${ISO_PATH}.md5" | cut -d' ' -f1)"
echo ""
echo "📋 Build Information:"
echo "   Version:  ${VERSION}-${CODENAME}"
echo "   Build ID: ${BUILD_ID}"
echo "   Arch:     ${BUILD_ARCH}"
echo "   Date:     ${BUILD_DATE}"
echo ""

# Generate build manifest
cat > "$OUTPUT_DIR/build-manifest.json" << EOF
{
    "name": "Obsidian OS",
    "version": "${VERSION}",
    "codename": "${CODENAME}",
    "build_id": "${BUILD_ID}",
    "build_date": "${BUILD_DATE}",
    "architecture": "${BUILD_ARCH}",
    "iso_file": "${ISO_NAME}",
    "iso_size": $(stat -c%s "$ISO_PATH"),
    "sha256": "$(cat "${ISO_PATH}.sha256" | cut -d' ' -f1)",
    "md5": "$(cat "${ISO_PATH}.md5" | cut -d' ' -f1)"
}
EOF

log_success "Build manifest saved to build-manifest.json"

# Store successful build marker
git rev-parse HEAD 2>/dev/null > "$PROJECT_DIR/.last-successful-build" || true
