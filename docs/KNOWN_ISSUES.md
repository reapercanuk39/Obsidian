# Obsidian OS Known Issues

## Boot Failure in QEMU

### Issue
The ISO fails to boot to desktop with the error:
```
request_module fs-squashfs succeeded, but still no fs?
Can not mount /dev/loop0 (/run/live/medium/.../filesystem.squashfs)
```

### Root Cause
- The squashfs filesystem uses **zstd compression**
- The kernel is `6.1.158-obsidian` 
- The squashfs kernel module was built for `6.1.0-41-amd64`
- This version mismatch prevents the squashfs from being mounted

### Solution Required
Rebuild the initramfs and squashfs with matching kernel versions:
1. Either rebuild kernel modules for 6.1.158-obsidian
2. Or use gzip compression for squashfs (universally supported)
3. Or regenerate initramfs with correct module versions

### Workaround
The ISO menu and bootloader work correctly. The kernel loads successfully.
Only the live-boot squashfs mounting fails.

## CI/CD Pipeline Status
- ✅ Path validation works
- ✅ Change detection works  
- ✅ ISO build script works
- ✅ ISO diff analysis works
- ⚠️ QEMU boot test detects failure (expected until squashfs fixed)
- ✅ Release automation ready
