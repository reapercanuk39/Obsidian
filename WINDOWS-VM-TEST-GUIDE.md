# Obsidian OS v1.0 - Windows VM Testing Guide

**ISO File:** `Obsidian-v1.0-Forged-20260105-2150.iso`  
**Size:** 1.4GB  
**Status:** ✅ Verified & Ready for Testing  
**Date:** 2026-01-05

---

## Quick Start - VirtualBox on Windows

### Prerequisites
1. **VirtualBox** installed (https://www.virtualbox.org/)
2. **Obsidian ISO** downloaded to your Windows machine
3. **4GB RAM** available for VM
4. **Virtualization** enabled in BIOS (Intel VT-x or AMD-V)

### Automated Test (Recommended)

We've provided a batch script that automatically creates and starts the VM:

```batch
1. Download test-windows-virtualbox.bat to your Windows PC
2. Edit the ISO_PATH in the file to match your ISO location
3. Double-click to run
4. VM will be created and started automatically
```

**Default ISO path:** `C:\Users\%USERNAME%\Downloads\Obsidian-v1.0-Forged-20260105-2150.iso`

### Manual Setup (5 minutes)

If you prefer to create the VM manually:

1. **Open VirtualBox**

2. **Create New VM**
   - Name: `Obsidian OS Test`
   - Type: Linux
   - Version: Debian (64-bit)
   - Memory: 4096 MB
   - Hard disk: Do not add (live CD only)

3. **Configure VM Settings**
   - System → Processor → CPUs: 2
   - Display → Video Memory: 128 MB
   - Display → Graphics Controller: VMSVGA
   - Storage → Add optical drive → Select Obsidian ISO

4. **Start VM**
   - Click "Start" button
   - VM will boot from ISO

---

## What to Test

### 1. Boot Sequence ✓

**Expected behavior:**
```
1. VirtualBox BIOS screen (2-3 seconds)
2. ISOLINUX boot menu appears
   - Shows "Start Obsidian OS"
   - No Debian/Ubuntu branding
3. Automatic boot after 5 seconds (or press Enter)
```

**What to check:**
- [ ] ISOLINUX menu displays correctly
- [ ] "Start Obsidian OS" is the default option
- [ ] No error messages during boot selection

### 2. Plymouth Boot Splash 🎨

**Expected behavior:**
```
After selecting "Start Obsidian OS":
1. Screen clears to black
2. Obsidian Forge animation begins:
   - Phase 1: Ember glow (orange/red fade-in)
   - Phase 2: Hammer strikes (sparks)
   - Phase 3: Meteor forge (intense heat)
   - Phase 4: Diamond crystallization (logo forms)
3. Animation loops until login screen appears
```

**What to check:**
- [ ] Plymouth animation displays (not text mode)
- [ ] Molten steel effects visible
- [ ] No "Debian" or "Ubuntu" branding
- [ ] Animation smooth and professional
- [ ] No visual artifacts or glitches

**If you see text instead of animation:**
- This may be normal for VirtualBox (limited graphics)
- Try: Settings → Display → Enable 3D Acceleration
- Or: This is cosmetic only, rest of system will work fine

### 3. Login Screen (LightDM) 🔐

**Expected behavior:**
```
After ~60-90 seconds total boot time:
1. LightDM login screen appears
2. Background: Forge wallpaper (molten steel imagery)
3. User avatar: Obsidian diamond logo
4. Title: "Obsidian"
5. Message: "Forged in molten steel."
6. Theme: VALYRIAN-Molten-Steel (dark with ember accents)
```

**What to check:**
- [ ] Login screen displays correctly
- [ ] Background wallpaper is Obsidian-themed
- [ ] No Debian/Ubuntu logos or text
- [ ] Username shows: "obsidian" or "Obsidian Live User"
- [ ] Password field present (may be empty for live system)
- [ ] Session selector shows "Xfce Session"
- [ ] Theme colors: dark background, ember orange accents

**Login credentials:**
- Username: `obsidian` or select from list
- Password: (none) - just press Enter or click "Log In"

### 4. Desktop Environment 🖥️

**Expected behavior:**
```
After login:
1. Xfce4 desktop loads
2. Panel at top/bottom with Obsidian styling
3. Wallpaper: Obsidian forge or custom wallpaper
4. Icons: Obsidian icon theme
5. Window decorations: VALYRIAN-Molten-Steel theme
```

**What to check:**
- [ ] Desktop loads without errors
- [ ] Wallpaper is Obsidian-branded
- [ ] Panel shows correctly (top or bottom)
- [ ] Application menu accessible
- [ ] Icons visible and themed
- [ ] Window borders have ember orange accents
- [ ] No Debian/Ubuntu branding in menus

### 5. Terminal & Branding 💻

**What to check:**
```bash
# Open terminal (Applications → Terminal or right-click desktop)
```

**Expected terminal appearance:**
- [ ] Background: Dark/black with transparency
- [ ] Foreground: Steel gray text
- [ ] Cursor: Ember orange block
- [ ] Prompt shows: 🔥 obsidian@obsidian ~/path
                    💎 $

**Test custom aliases:**
```bash
# Try these commands:
forge         # Should show ASCII logo + system info
forge-info    # Should show Obsidian banner
colors        # Should display color palette
ember         # Should launch htop (system monitor)
temper        # Should show temperature or message
```

**What to check:**
- [ ] Custom prompt displays with emoji
- [ ] Colors: ember orange, steel gray, cosmic blue
- [ ] Aliases work correctly
- [ ] Terminal theme matches Obsidian design
- [ ] No Debian references in terminal

### 6. System Information 📊

**Check OS details:**
```bash
# In terminal, run:
cat /etc/os-release
```

**Expected output:**
```
NAME="Obsidian"
VERSION="1.0"
ID=obsidian
ID_LIKE=debian
PRETTY_NAME="Obsidian 1.0"
VERSION_ID="1.0"
```

**What to check:**
- [ ] OS name is "Obsidian" (not Debian)
- [ ] Version shows "1.0"
- [ ] No Ubuntu references

### 7. Applications & Functionality 🔧

**Test basic functionality:**
- [ ] File Manager opens (Thunar)
- [ ] Web Browser works (if included)
- [ ] Text Editor opens
- [ ] System Settings accessible
- [ ] Mouse and keyboard responsive
- [ ] Window management works (minimize, maximize, close)

### 8. Performance ⚡

**What to observe:**
- [ ] Boot time: < 2 minutes (should be ~60-90 seconds)
- [ ] Desktop responsive (no lag)
- [ ] Applications launch quickly
- [ ] Memory usage reasonable (check with `htop` or `ember` alias)
- [ ] No crashes or freezes

---

## Troubleshooting

### Issue: VM Won't Boot

**Symptoms:** Black screen, "No bootable device" error

**Solutions:**
1. Verify ISO is attached to VM optical drive
2. Check boot order: CD/DVD should be first
3. Try BIOS mode (disable EFI in VM settings)
4. Increase memory to 4GB if less

### Issue: Slow Performance

**Symptoms:** Laggy mouse, slow windows

**Solutions:**
1. Close other applications on Windows host
2. Increase VM memory to 4GB or more
3. Allocate more CPU cores (2-4)
4. Enable hardware virtualization in BIOS
5. Disable Hyper-V if using VirtualBox (Windows feature conflict)

### Issue: No Graphics / Text Mode Only

**Symptoms:** No Plymouth splash, text boot messages

**Solutions:**
- This is normal for some VM configurations
- Enable 3D acceleration in Display settings
- Increase video memory to 128MB
- Try different graphics controller (VMSVGA, VBoxVGA)
- **Note:** System will work fine, just no boot animation

### Issue: Login Screen Not Appearing

**Symptoms:** Stuck at boot, no login prompt

**Solutions:**
1. Wait 2-3 minutes (first boot can be slower)
2. Press Ctrl+Alt+F1 to switch to text console
3. Check logs: `journalctl -xe`
4. Try safe mode boot (select from menu if available)

### Issue: Keyboard Not Working

**Symptoms:** Can't type password or commands

**Solutions:**
1. Click inside VM window to capture input
2. Check VM → Input → Keyboard → Capture
3. Host key is Right Ctrl (to release keyboard)
4. Try USB keyboard if using PS/2 emulation

---

## VirtualBox Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Right Ctrl` | Release mouse/keyboard from VM |
| `Right Ctrl + F` | Toggle fullscreen |
| `Right Ctrl + P` | Pause VM |
| `Right Ctrl + R` | Reset VM (reboot) |
| `Right Ctrl + H` | Shutdown VM |

---

## Testing Checklist

Print this checklist or keep it open during testing:

### Boot & Installation
- [ ] VM boots successfully
- [ ] ISOLINUX menu appears
- [ ] No boot errors

### Visual & Branding
- [ ] Plymouth splash displays (or text mode acceptable)
- [ ] Login screen shows Obsidian theme
- [ ] Desktop has correct wallpaper
- [ ] Icons are themed
- [ ] No Debian/Ubuntu logos visible

### Functionality
- [ ] Login works (with or without password)
- [ ] Desktop loads completely
- [ ] Terminal opens and works
- [ ] Custom aliases functional
- [ ] File manager works
- [ ] Applications launch

### Performance
- [ ] Boot time acceptable (< 2 minutes)
- [ ] Desktop responsive
- [ ] No crashes or freezes
- [ ] Memory usage reasonable

### Branding Verification
- [ ] OS name is "Obsidian"
- [ ] Version is "1.0"
- [ ] Terminal shows custom prompt
- [ ] Theme colors match (ember orange, steel gray)

---

## Reporting Results

After testing, please document:

1. **Environment:**
   - Windows version (10/11)
   - VirtualBox version
   - Host RAM available
   - CPU model

2. **Results:**
   - ✅ What worked correctly
   - ⚠️  What had minor issues
   - ❌ What failed completely

3. **Screenshots:** (if possible)
   - Boot menu
   - Plymouth splash (if visible)
   - Login screen
   - Desktop with terminal
   - System information

4. **Timing:**
   - Total boot time (seconds)
   - Time to login screen
   - Time to desktop

---

## Expected Test Duration

- **Setup:** 5-10 minutes (first time)
- **Boot test:** 2-3 minutes per test
- **Full feature test:** 10-15 minutes
- **Total:** ~20-30 minutes for complete testing

---

## Clean Up

After testing, you can:

1. **Keep VM for future use:**
   - VM uses no disk space (live CD)
   - Just shut down VM

2. **Remove VM:**
   - VirtualBox → Right-click VM → Remove
   - Select "Delete all files"
   - Or run: `VBoxManage unregistervm "Obsidian OS Test" --delete`

---

## Support & Questions

If you encounter issues:

1. Check the troubleshooting section above
2. Review `BOOT-FIX-COMPLETE.md` for known issues
3. Check `CROSS-PLATFORM-TEST-RESULTS.md` for platform notes
4. Verify ISO MD5 checksum matches

---

## Success Criteria

✅ **Test is SUCCESSFUL if:**
- VM boots without errors
- Login screen appears
- Desktop loads
- Obsidian branding is visible
- No Debian/Ubuntu references visible
- Basic functionality works

⚠️ **Test is ACCEPTABLE if:**
- Plymouth splash doesn't show (but login screen does)
- Minor cosmetic issues
- Everything else works correctly

❌ **Test FAILED if:**
- VM won't boot at all
- Kernel panic or critical errors
- Desktop doesn't load
- Major functionality broken

---

## Additional Notes

### VirtualBox vs VMware vs Hyper-V

**VirtualBox (Recommended for testing):**
- ✅ Free and open source
- ✅ Easy to use
- ✅ Cross-platform
- ⚠️  Slightly slower than VMware
- ⚠️  Plymouth may not render properly

**VMware Workstation:**
- ✅ Better performance
- ✅ Better graphics support
- ✅ Plymouth more likely to work
- ❌ Commercial license required

**Hyper-V:**
- ✅ Native Windows hypervisor
- ✅ Good performance
- ⚠️  Windows 10/11 Pro required
- ⚠️  Disable Secure Boot for best results

### Live System Notes

This ISO is a **live system**, meaning:
- No installation required for testing
- Changes are not persistent (lost on reboot)
- Fast testing and evaluation
- Can be installed to disk if desired (installer may be included)

---

## Quick Reference Commands

```bash
# System info
uname -a
cat /etc/os-release

# Check branding
ls /usr/share/plymouth/themes/
ls /usr/share/themes/

# View logs
journalctl -b
dmesg | less

# Resource monitoring
htop          # or use alias: ember
free -h       # memory usage
df -h         # disk usage

# Test aliases
forge         # System banner
colors        # Color palette
temper        # Temperature (if sensors available)
```

---

**Document Version:** 1.0  
**Created:** 2026-01-05  
**For:** Obsidian OS v1.0 - Forged Edition  
**ISO:** Obsidian-v1.0-Forged-20260105-2150.iso

🔥 **Obsidian OS - Forged in Molten Steel** 💎
