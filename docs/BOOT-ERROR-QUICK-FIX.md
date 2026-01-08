# 🔥 Obsidian OS - Quick Reference for Boot Errors

## ❌ Error: file '/OBSIDIAN/VMLINUZ' not found

### Cause
EFI images have lowercase paths, ISO has UPPERCASE files.

### Fix (Run as root)
```bash
cd /root/obsidian-build
sudo ./scripts/fix-efi-images.sh
./scripts/rebuild-iso.sh
```

### Why It Happens
- ISO9660 creates UPPERCASE filenames
- EFI images contain embedded grub.cfg files
- These embedded configs don't auto-update
- USB/UEFI boot reads from embedded configs

### Prevention
The rebuild script now auto-checks EFI images. Just use:
```bash
./scripts/rebuild-iso.sh
```

It will automatically run the fix if needed.

---

## 📋 Boot Config Locations

| # | Location | Usage |
|---|----------|-------|
| 1 | `iso/boot/grub/grub.cfg` | UEFI (direct) |
| 2 | `iso/isolinux/isolinux.cfg` | BIOS |
| 3 | `iso/boot/grub/efi.img → EFI/boot/grub.cfg` | **USB UEFI** ⚠️ |
| 4 | `iso/efi/efi.img → EFI/boot/grub.cfg` | **USB UEFI** ⚠️ |

**All 4 must have UPPERCASE paths!**

---

## ✅ Correct Paths

```
/OBSIDIAN/VMLINUZ          ← UPPERCASE
/OBSIDIAN/INITRD           ← UPPERCASE  
live-media-path=/OBSIDIAN  ← UPPERCASE
```

---

## 🔍 Quick Verify

```bash
# Check EFI Image 1
mount -o loop iso/boot/grub/efi.img /tmp/check
grep VMLINUZ /tmp/check/EFI/boot/grub.cfg
umount /tmp/check

# Check EFI Image 2
mount -o loop iso/efi/efi.img /tmp/check
grep VMLINUZ /tmp/check/EFI/boot/grub.cfg
umount /tmp/check
```

Should output: `/OBSIDIAN/VMLINUZ` (UPPERCASE)

---

## 📚 Full Documentation

See: `docs/EFI-BOOT-FIX-PERMANENT.md`
