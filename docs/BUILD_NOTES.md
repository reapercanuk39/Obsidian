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
6. **Release Automation** - Creates GitHub releases
7. **Documentation Updates** - Keeps docs in sync

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

### Validation

```bash
# Validate paths (check for forbidden Termux paths)
./scripts/validate-iso-prefix.sh rootfs

# Run boot test
./scripts/qemu-boot-test.sh Obsidian-*.iso

# Compare ISOs
sudo ./scripts/iso-diff.sh old.iso new.iso report.md
```

## CI/CD Triggers

The pipeline runs automatically on:
- Push to `main` or `master` branch
- Pull requests
- Manual workflow dispatch
- Nightly schedule (2 AM UTC)

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

### Path Validation Failures

1. Check violations.txt for the specific paths
2. Search for Termux-related strings in the rootfs
3. Update the affected files to use Obsidian paths
