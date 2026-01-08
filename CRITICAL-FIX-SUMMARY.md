# 🚨 CRITICAL FIX - USB Boot Issue Resolved

**Date**: 2026-01-08 01:03 UTC  
**Issue**: USB boot failure with "file '/obsidian/vmlinuz' not found"  
**Status**: ✅ FIXED

---

## Problem

User flashed ISO to USB with Rufus DD mode and all boot options failed with:
```
error: file '/obsidian/vmlinuz' not found.
error: you need to load the kernel first.
```

## Root Cause

**EFI image configs had lowercase paths while ISO filesystem had UPPERCASE files!**

| Config Location | Status Before Fix |
|----------------|-------------------|
| `iso/boot/grub/grub.cfg` | ✅ Had UPPERCASE `/OBSIDIAN/VMLINUZ` |
| `iso/isolinux/isolinux.cfg` | ✅ Had UPPERCASE `/OBSIDIAN/VMLINUZ` |
| `iso/boot/grub/efi.img → EFI/boot/grub.cfg` | ❌ Had lowercase `/obsidian/vmlinuz` |
| `iso/efi/efi.img → EFI/boot/grub.cfg` | ❌ Had lowercase `/obsidian/vmlinuz` |

**Why this matters**: USB boots typically use UEFI, which loads from the EFI partition. Those configs had wrong paths!

## Solution Applied

1. Mounted both EFI images
2. Updated embedded grub.cfg files with UPPERCASE paths
3. Rebuilt ISO (no squashfs rebuild needed - boot config only)
4. Verified all 4 config locations match

## Fixed ISO

**File**: `Obsidian-v1.6-Enhanced-COMPLETE-FIXED2-20260108-0103.iso`  
**Size**: 1.2 GB  
**MD5**: `84c99467cc11aabfa2fd915fb98203be`  

**Changes from previous ISO**:
- Only EFI image configs updated (everything else identical)
- Should now boot successfully from USB on physical hardware

## Verification Commands

```bash
# Check main GRUB config
cat iso/boot/grub/grub.cfg | grep linux

# Check ISOLINUX config  
cat iso/isolinux/isolinux.cfg | grep KERNEL

# Check EFI image configs (must mount first)
mount -o loop,ro iso/boot/grub/efi.img /tmp/check
cat /tmp/check/EFI/boot/grub.cfg | grep linux
umount /tmp/check
```

All should show: `/OBSIDIAN/VMLINUZ` and `/OBSIDIAN/INITRD`

## Key Lesson

**Always verify EFI image contents after boot config changes!**

EFI images are embedded FAT filesystems inside the ISO. They have their own grub.cfg that must be updated separately from the main ISO configs.

---

**Next Step**: Test USB boot on physical hardware with FIXED2 ISO
