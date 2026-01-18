#!/bin/bash
#############################################
# OBSIDIAN ISO DEBUG TOOLS INSTALLER
# Installs all tools needed for ISO analysis,
# extraction, and debugging
#############################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔧 OBSIDIAN ISO DEBUG TOOLS INSTALLER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${YELLOW}⚠ Not running as root. Will use sudo for installations.${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

#############################################
# DETECT PACKAGE MANAGER
#############################################

detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_package_manager)
echo "Detected package manager: $PKG_MANAGER"
echo ""

#############################################
# TOOL DEFINITIONS
#############################################

# Define tools with their packages for different distros
declare -A TOOLS_APT=(
    ["xorriso"]="xorriso"
    ["isoinfo"]="genisoimage"
    ["binwalk"]="binwalk"
    ["fls"]="sleuthkit"
    ["mksquashfs"]="squashfs-tools"
    ["qemu-img"]="qemu-utils"
    ["7z"]="p7zip-full"
    ["debugfs"]="e2fsprogs"
    ["mount"]="mount"
    ["losetup"]="mount"
    ["mkisofs"]="genisoimage"
    ["grub-mkimage"]="grub2-common"
    ["fakeroot"]="fakeroot"
    ["rsync"]="rsync"
    ["jq"]="jq"
    ["socat"]="socat"
    ["strings"]="binutils"
    ["file"]="file"
    ["lsblk"]="util-linux"
    ["fdisk"]="fdisk"
    ["parted"]="parted"
    ["kpartx"]="kpartx"
    ["dmsetup"]="dmsetup"
    ["blkid"]="util-linux"
)

declare -A TOOLS_DNF=(
    ["xorriso"]="xorriso"
    ["isoinfo"]="genisoimage"
    ["binwalk"]="binwalk"
    ["fls"]="sleuthkit"
    ["mksquashfs"]="squashfs-tools"
    ["qemu-img"]="qemu-img"
    ["7z"]="p7zip-plugins"
    ["debugfs"]="e2fsprogs"
    ["grub-mkimage"]="grub2-tools"
    ["fakeroot"]="fakeroot"
    ["rsync"]="rsync"
    ["jq"]="jq"
    ["socat"]="socat"
)

declare -A TOOLS_PACMAN=(
    ["xorriso"]="xorriso"
    ["isoinfo"]="cdrtools"
    ["binwalk"]="binwalk"
    ["fls"]="sleuthkit"
    ["mksquashfs"]="squashfs-tools"
    ["qemu-img"]="qemu"
    ["7z"]="p7zip"
    ["debugfs"]="e2fsprogs"
    ["grub-mkimage"]="grub"
    ["fakeroot"]="fakeroot"
    ["rsync"]="rsync"
    ["jq"]="jq"
    ["socat"]="socat"
)

#############################################
# INSTALLATION FUNCTIONS
#############################################

install_apt() {
    local packages=("$@")
    echo -e "${BLUE}Installing via apt: ${packages[*]}${NC}"
    $SUDO apt-get update -qq
    $SUDO apt-get install -y "${packages[@]}"
}

install_dnf() {
    local packages=("$@")
    echo -e "${BLUE}Installing via dnf: ${packages[*]}${NC}"
    $SUDO dnf install -y "${packages[@]}"
}

install_pacman() {
    local packages=("$@")
    echo -e "${BLUE}Installing via pacman: ${packages[*]}${NC}"
    $SUDO pacman -S --noconfirm "${packages[@]}"
}

install_yum() {
    local packages=("$@")
    echo -e "${BLUE}Installing via yum: ${packages[*]}${NC}"
    $SUDO yum install -y "${packages[@]}"
}

install_zypper() {
    local packages=("$@")
    echo -e "${BLUE}Installing via zypper: ${packages[*]}${NC}"
    $SUDO zypper install -y "${packages[@]}"
}

#############################################
# MAIN INSTALLATION
#############################################

echo "📋 Checking and installing required tools..."
echo "─────────────────────────────────────────────"

PACKAGES_TO_INSTALL=()
INSTALLED_COUNT=0
FAILED_COUNT=0

check_and_queue_tool() {
    local tool="$1"
    local package=""
    
    case "$PKG_MANAGER" in
        apt)
            package="${TOOLS_APT[$tool]:-}"
            ;;
        dnf)
            package="${TOOLS_DNF[$tool]:-}"
            ;;
        pacman)
            package="${TOOLS_PACMAN[$tool]:-}"
            ;;
        yum)
            package="${TOOLS_DNF[$tool]:-}"  # Similar to dnf
            ;;
        *)
            package=""
            ;;
    esac
    
    if command -v "$tool" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $tool (already installed)"
        ((INSTALLED_COUNT++))
    elif [ -n "$package" ]; then
        echo -e "${YELLOW}○${NC} $tool (will install: $package)"
        PACKAGES_TO_INSTALL+=("$package")
    else
        echo -e "${RED}✗${NC} $tool (no package mapping for $PKG_MANAGER)"
        ((FAILED_COUNT++))
    fi
}

# Essential ISO tools
echo ""
echo "ISO Creation/Analysis:"
for tool in xorriso isoinfo mkisofs mksquashfs; do
    check_and_queue_tool "$tool"
done

echo ""
echo "Filesystem Analysis:"
for tool in fls debugfs binwalk 7z; do
    check_and_queue_tool "$tool"
done

echo ""
echo "QEMU/Virtualization:"
for tool in qemu-img; do
    check_and_queue_tool "$tool"
done

echo ""
echo "Build Utilities:"
for tool in fakeroot rsync jq socat strings file; do
    check_and_queue_tool "$tool"
done

echo ""
echo "Disk Utilities:"
for tool in mount losetup lsblk fdisk parted kpartx blkid; do
    check_and_queue_tool "$tool"
done

echo ""
echo "Bootloader Tools:"
for tool in grub-mkimage; do
    check_and_queue_tool "$tool"
done

#############################################
# INSTALL QUEUED PACKAGES
#############################################

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo ""
    echo "─────────────────────────────────────────────"
    echo "Installing ${#PACKAGES_TO_INSTALL[@]} packages..."
    echo ""
    
    # Remove duplicates
    PACKAGES_TO_INSTALL=($(echo "${PACKAGES_TO_INSTALL[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    
    case "$PKG_MANAGER" in
        apt)
            install_apt "${PACKAGES_TO_INSTALL[@]}"
            ;;
        dnf)
            install_dnf "${PACKAGES_TO_INSTALL[@]}"
            ;;
        yum)
            install_yum "${PACKAGES_TO_INSTALL[@]}"
            ;;
        pacman)
            install_pacman "${PACKAGES_TO_INSTALL[@]}"
            ;;
        zypper)
            install_zypper "${PACKAGES_TO_INSTALL[@]}"
            ;;
        *)
            echo -e "${RED}❌ Unsupported package manager: $PKG_MANAGER${NC}"
            echo "Please install these packages manually:"
            printf "  - %s\n" "${PACKAGES_TO_INSTALL[@]}"
            exit 1
            ;;
    esac
else
    echo ""
    echo -e "${GREEN}All required tools are already installed!${NC}"
fi

#############################################
# INSTALL QEMU (special handling)
#############################################

echo ""
echo "─────────────────────────────────────────────"
echo "Checking QEMU installation..."

if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo "Installing QEMU system emulator..."
    case "$PKG_MANAGER" in
        apt)
            $SUDO apt-get install -y qemu-system-x86 qemu-utils
            ;;
        dnf|yum)
            $SUDO $PKG_MANAGER install -y qemu-kvm qemu-img
            ;;
        pacman)
            $SUDO pacman -S --noconfirm qemu-full
            ;;
        zypper)
            $SUDO zypper install -y qemu-x86
            ;;
    esac
else
    echo -e "${GREEN}✓${NC} qemu-system-x86_64 (already installed)"
fi

#############################################
# INSTALL ISOLINUX/SYSLINUX
#############################################

echo ""
echo "─────────────────────────────────────────────"
echo "Checking ISOLINUX/SYSLINUX installation..."

if [ ! -f "/usr/lib/ISOLINUX/isolinux.bin" ] && [ ! -f "/usr/lib/syslinux/bios/isolinux.bin" ]; then
    echo "Installing ISOLINUX/SYSLINUX..."
    case "$PKG_MANAGER" in
        apt)
            $SUDO apt-get install -y isolinux syslinux syslinux-common
            ;;
        dnf|yum)
            $SUDO $PKG_MANAGER install -y syslinux syslinux-nonlinux
            ;;
        pacman)
            $SUDO pacman -S --noconfirm syslinux
            ;;
        zypper)
            $SUDO zypper install -y syslinux
            ;;
    esac
else
    echo -e "${GREEN}✓${NC} ISOLINUX/SYSLINUX (already installed)"
fi

#############################################
# OPTIONAL: Python tools for advanced analysis
#############################################

echo ""
echo "─────────────────────────────────────────────"
echo "Checking Python analysis tools..."

if command -v pip3 &>/dev/null; then
    for py_tool in yara-python pefile; do
        if ! python3 -c "import ${py_tool//-/_}" 2>/dev/null; then
            echo "Installing Python tool: $py_tool"
            pip3 install --user "$py_tool" 2>/dev/null || true
        else
            echo -e "${GREEN}✓${NC} $py_tool (Python package)"
        fi
    done
else
    echo -e "${YELLOW}⚠${NC} pip3 not available, skipping Python tools"
fi

#############################################
# SUMMARY
#############################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ INSTALLATION COMPLETE${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📋 Tool Summary:"
echo ""

# Verify all tools
for tool in xorriso isoinfo mksquashfs unsquashfs binwalk 7z qemu-system-x86_64 qemu-img \
            debugfs fakeroot rsync jq socat strings file mount losetup; do
    if command -v "$tool" &>/dev/null; then
        version=$($tool --version 2>&1 | head -1 || echo "installed")
        echo -e "  ${GREEN}✓${NC} $tool"
    else
        echo -e "  ${RED}✗${NC} $tool (not found)"
    fi
done

echo ""
echo "📁 ISOLINUX locations:"
for path in /usr/lib/ISOLINUX /usr/lib/syslinux/bios /usr/share/syslinux; do
    if [ -d "$path" ]; then
        echo "  ✓ $path"
    fi
done

echo ""
echo "You're ready to build and debug Obsidian ISO images!"
