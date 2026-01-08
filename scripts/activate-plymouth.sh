#!/bin/bash
set -e

echo "=== Activating Obsidian Minimal Plymouth Theme ==="

# Enter chroot
chroot rootfs /bin/bash << 'CHROOT_EOF'
set -e

# Install the new theme as an alternative
echo "Installing Plymouth theme alternative..."
update-alternatives --install \
    /usr/share/plymouth/themes/default.plymouth \
    default.plymouth \
    /usr/share/plymouth/themes/obsidian-minimal/obsidian-minimal.plymouth \
    100

# Set it as default
echo "Setting as default theme..."
update-alternatives --set default.plymouth \
    /usr/share/plymouth/themes/obsidian-minimal/obsidian-minimal.plymouth

# Update initramfs
echo "Rebuilding initramfs..."
update-initramfs -u -k all

echo "Plymouth theme activated successfully!"
CHROOT_EOF

echo "=== Plymouth theme activation complete ==="
