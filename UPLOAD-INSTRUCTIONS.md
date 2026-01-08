# GitHub Releases v1.6 Complete - Upload Instructions

## 📦 Files Ready for Upload

### ISO Files (Choose One or Both)

1. **Complete (ZSTD) - Recommended**
   - File: `Obsidian-v1.6-Enhanced-COMPLETE-20260108-0049.iso`
   - Size: 1.2 GB
   - MD5: `5358c617b18044f2f6580aca8396a091`
   - Best for: Fast downloads, modern systems

2. **Lite (XZ) - Alternative**
   - File: `Obsidian-v1.6-Enhanced-Lite-20260108-0041.iso`
   - Size: 1.2 GB
   - MD5: `2c8db64b4271c72007f2d7fbbe55a8c7`
   - Best for: Traditional distribution, maximum compatibility

### Documentation
- `V1.6-COMPLETE-RELEASE-NOTES.md` - Full release notes (attach to release)

---

## 🚀 GitHub Releases Steps

### 1. Create New Release
```bash
# Navigate to: https://github.com/reapercanuk39/Obsidian/releases/new

Tag: v1.6-complete
Title: Obsidian OS v1.6 Complete Enhancement Package
```

### 2. Release Description
Copy contents from `V1.6-COMPLETE-RELEASE-NOTES.md` or use this summary:

```markdown
# Obsidian OS v1.6 Complete 🔥

**All enhancements activated**: Plymouth theme, wallpaper collection, performance optimizations

## What's New
✅ Simplified Plymouth boot splash (pulsing diamond)
✅ 8 forge-themed wallpapers included
✅ Papirus icons (ember orange folders)
✅ Preload for faster app launches
✅ 292 MB size optimization
✅ Critical boot fixes (BIOS + UEFI)

## Downloads

### Complete (Recommended)
- **Size**: 1.2 GB
- **Compression**: ZSTD Level 15
- **MD5**: `5358c617b18044f2f6580aca8396a091`

### Lite (Alternative)
- **Size**: 1.2 GB  
- **Compression**: XZ (maximum)
- **MD5**: `2c8db64b4271c72007f2d7fbbe55a8c7`

## Boot Testing
✅ Tested on physical hardware (USB boot)
✅ BIOS and UEFI support verified
✅ All boot paths fixed (uppercase)

## Installation
**Bootable USB** (Linux):
```bash
sudo dd if=Obsidian-v1.6-Enhanced-COMPLETE-*.iso of=/dev/sdX bs=4M status=progress
```

**Windows**: Use Rufus or Etcher

**Live Session**:
- Username: `linuxuser`
- Password: `password`

---

**Full Documentation**: See attached release notes and `REBUILD-CHANGELOG.md` in repository
```

### 3. Upload Files
Drag and drop these files to the release:
- ✅ `Obsidian-v1.6-Enhanced-COMPLETE-20260108-0049.iso`
- ✅ `Obsidian-v1.6-Enhanced-COMPLETE-20260108-0049.iso.md5`
- ✅ `Obsidian-v1.6-Enhanced-Lite-20260108-0041.iso`
- ✅ `Obsidian-v1.6-Enhanced-Lite-20260108-0041.iso.md5`
- ✅ `V1.6-COMPLETE-RELEASE-NOTES.md`

### 4. Publish
- Mark as "Latest release"
- Click "Publish release"

---

## 📊 Current Status

### Completed ✅
- [x] Plymouth theme activated
- [x] 8 wallpapers created and set as default
- [x] Complete ISO built (ZSTD)
- [x] Lite ISO built (XZ)
- [x] Documentation updated
- [x] Git committed and pushed
- [x] Release notes created

### Ready for Upload ⏳
- [ ] Upload Complete ISO to GitHub Releases
- [ ] Upload Lite ISO to GitHub Releases
- [ ] Attach release notes
- [ ] Publish release

---

## 🎯 Quick Commands

### Verify Files
```bash
ls -lh Obsidian-v1.6-Enhanced-*.iso*
md5sum Obsidian-v1.6-Enhanced-*.iso
```

### Test in VM (Optional)
```bash
qemu-system-x86_64 \
  -cdrom Obsidian-v1.6-Enhanced-COMPLETE-20260108-0049.iso \
  -m 4096 \
  -boot d \
  -enable-kvm
```

---

## 📝 Notes

**Previous Versions**:
- v1.6-Enhanced (old): Can be deleted or archived
- v1.6-Fixed: Keep for reference (first boot fix)

**File Sizes**:
- Both Complete and Lite are 1.2 GB (identical final size)
- Choose based on compression preference, not size

**GitHub Limits**:
- Max file size: 2 GB ✅
- Both ISOs are under limit ✅

---

**Ready to upload!** 🚀
