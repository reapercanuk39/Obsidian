# Build Notes

Last updated: 2026-01-18

## Latest Build

This document is automatically updated by the CI/CD pipeline after each successful build.

## Build System Overview

Obsidian OS uses a fully automated CI/CD pipeline powered by GitHub Actions. The pipeline handles:

1. **Path Validation** - Scans for forbidden Termux/Android paths
2. **Change Detection** - Determines which components need rebuild  
3. **ISO Build** - Assembles rootfs, creates squashfs, builds hybrid ISO
4. **ISO Diff** - Compares with previous releases
5. **QEMU Boot Test** - Headless boot verification
6. **VirtualBox Boot Test** - Graphical boot testing with screenshots
7. **Release Automation** - Creates GitHub releases
8. **Documentation Updates** - Keeps docs in sync

## Manual Build Instructions

### Prerequisites

```bash
# Install required tools
sudo ./scripts/install-iso-debug-tools.sh
```

### Building the ISO

```bash
# Full build
sudo ./scripts/build-obsidian-iso.sh

# With custom version
VERSION=2.2 CODENAME=BASTION sudo ./scripts/build-obsidian-iso.sh
```

### Rebuilding Initramfs

If you need to regenerate the initramfs (e.g., after changing live-boot configuration):

```bash
# Rebuild initramfs with live-boot support
sudo ./scripts/rebuild-initramfs.sh

# Then rebuild the ISO
sudo ./scripts/build-obsidian-iso.sh
```

### Validation

```bash
# Validate paths (check for forbidden Termux paths)
./scripts/validate-iso-prefix.sh rootfs

# Run QEMU boot test (headless)
./scripts/qemu-boot-test.sh Obsidian-*.iso

# Run VirtualBox boot test (graphical, with screenshots)
./scripts/virtualbox-boot-test.sh Obsidian-*.iso

# Compare ISOs
sudo ./scripts/iso-diff.sh old.iso new.iso report.md
```

## Initramfs and Live-boot

### How It Works

Obsidian OS uses `live-boot` to boot from the ISO as a live system:

1. **BIOS/UEFI** loads the bootloader (ISOLINUX or GRUB)
2. **Bootloader** loads the kernel and initramfs
3. **Initramfs** runs live-boot scripts to:
   - Find the live medium (ISO/USB)
   - Mount the squashfs filesystem
   - Set up the overlay filesystem
   - Pivot to the live root
4. **Systemd** takes over and boots the full system

### Key Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `boot=live` | Required | Enables live-boot mode |
| `live-media-path=/OBSIDIAN` | Required | Path to squashfs inside ISO |
| `components` | Optional | Enables component loading |
| `quiet` | Optional | Reduces boot messages |
| `splash` | Optional | Shows Plymouth boot splash |
| `toram` | Optional | Copies squashfs to RAM |
| `noswap` | Optional | Disables swap (forensic mode) |

### Directory Structure

```
iso/
├── OBSIDIAN/
│   ├── vmlinuz              # Kernel
│   ├── initrd               # Initramfs (live-boot enabled)
│   └── filesystem.squashfs  # Root filesystem
├── isolinux/
│   ├── isolinux.cfg         # BIOS boot configuration
│   └── *.c32                # SYSLINUX modules
├── boot/grub/
│   └── grub.cfg             # EFI boot configuration
└── .disk/
    └── info                 # ISO identifier
```

### Rebuilding Initramfs

The initramfs must include live-boot hooks to properly boot the live system:

```bash
# Inside chroot environment
update-initramfs -u -k all

# Or using the rebuild script
sudo ./scripts/rebuild-initramfs.sh
```

The `rebuild-initramfs.sh` script:
1. Validates live-boot is installed
2. Configures `/etc/live/boot.conf` with Obsidian paths
3. Runs `mkinitramfs` in chroot
4. Validates the output includes live-boot scripts
5. Copies the new initrd to `iso/OBSIDIAN/initrd`

### Troubleshooting Boot Issues

If the ISO fails to boot:

1. **Check bootloader config**: Verify `live-media-path=/OBSIDIAN` in isolinux.cfg
2. **Validate initramfs**: Ensure live-boot scripts are included
3. **Check squashfs path**: Must be at `/OBSIDIAN/filesystem.squashfs`
4. **Review screenshots**: VirtualBox test captures boot stages
5. **Enable debug boot**: Add `debug` to kernel parameters

## VirtualBox Testing

### Running Locally

```bash
# Basic test
./scripts/virtualbox-boot-test.sh Obsidian-*.iso

# With custom settings
VBOX_MEMORY=4096 BOOT_TIMEOUT=600 ./scripts/virtualbox-boot-test.sh Obsidian-*.iso
```

### Screenshot Stages

The VirtualBox test captures screenshots at:

| Time | Stage | Expected Content |
|------|-------|------------------|
| 5s | BIOS/Bootloader | VirtualBox BIOS screen |
| 15s | Boot menu | ISOLINUX/GRUB menu |
| 30s | Kernel loading | Kernel boot messages |
| 60s | Initramfs | live-boot progress |
| 120s | System services | Systemd service startup |
| 180s | Desktop/Login | Live desktop or login prompt |

### Artifacts

VirtualBox tests produce:
- `artifacts/virtualbox/screenshots/` - Boot stage screenshots
- `artifacts/virtualbox/logs/` - VM and VBox logs
- `artifacts/virtualbox/SUMMARY.md` - Test results

## CI/CD Triggers

The pipeline runs automatically on:
- Push to `main` or `master` branch
- Pull requests
- Manual workflow dispatch
- Nightly schedule (2 AM UTC)

### Manual Dispatch Options

| Option | Description |
|--------|-------------|
| `force_rebuild` | Ignore change detection, rebuild everything |
| `run_qemu_test` | Run headless QEMU boot test (default: true) |
| `run_virtualbox_test` | Run graphical VirtualBox boot test |
| `rebuild_initramfs` | Force initramfs rebuild before ISO |
| `create_release` | Create GitHub release after build |
| `version` | Override version number |

## Configuration

See `.github/workflows/obsidian-iso-ci.yml` for the complete pipeline configuration.

## Troubleshooting

### Build Failures

1. Check the GitHub Actions logs for the specific error
2. Download the failure artifacts for detailed logs
3. Run the failing script locally to reproduce

### Boot Test Failures

1. Check the console.log in the test artifacts
2. Look for kernel panic or systemd errors
3. Verify initrd contains live-boot components
4. Review VirtualBox screenshots for visual clues

### Path Validation Failures

1. Check violations.txt for the specific paths
2. Search for Termux-related strings in the rootfs
3. Update the affected files to use Obsidian paths
