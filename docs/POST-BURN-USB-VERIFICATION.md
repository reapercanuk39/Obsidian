# Obsidian OS - Post-Burn USB Verification Guide
## For Physical Hardware Testing

---

## ⚠️ BEFORE YOU BURN

Run the pre-burn validation to catch issues BEFORE wasting a USB burn:

```bash
sudo ./scripts/pre-burn-validation.sh
```

If you see **CRITICAL** failures, DO NOT burn until fixed!

---

## 🔥 Burning the ISO

### Windows (Rufus)
1. Download Rufus: https://rufus.ie/
2. Insert USB drive (8GB+ recommended)
3. Select your USB drive
4. Click SELECT and choose `Obsidian-v1.7.iso`
5. **CRITICAL**: When prompted, choose **DD Image mode** (NOT ISO mode)
6. Click START and wait for completion

### Linux
```bash
# Find your USB device (BE CAREFUL - wrong device = data loss!)
lsblk

# Write ISO (replace sdX with your device - e.g., sdb, sdc)
sudo dd if=Obsidian-v1.7.iso of=/dev/sdX bs=4M status=progress conv=fsync
sudo sync
```

---

## 🧪 Physical Hardware Test Checklist

### Phase 1: Boot Menu

| Test | Expected Result | Pass/Fail |
|------|-----------------|-----------|
| USB appears in BIOS boot menu | USB drive listed as bootable | ☐ |
| Boot menu loads | "OBSIDIAN OS v1.7 - Forged in Molten Steel" title | ☐ |
| Menu is navigable | Arrow keys work, entries highlight | ☐ |
| Timer counts down | 10 second timeout visible | ☐ |

### Phase 2: Kernel Loading

| Test | Expected Result | Pass/Fail |
|------|-----------------|-----------|
| Select "Start Obsidian OS" | No errors, kernel starts loading | ☐ |
| **NO** "file not found" error | Should NOT see `/OBSIDIAN/VMLINUZ not found` | ☐ |
| **NO** "you need to load the kernel first" | Should NOT see this error | ☐ |
| Boot messages or Plymouth splash | Screen shows progress | ☐ |

### Phase 3: Login Screen

| Test | Expected Result | Pass/Fail |
|------|-----------------|-----------|
| LightDM login screen appears | Obsidian themed login | ☐ |
| Mouse cursor visible | Cursor moves with mouse | ☐ |
| Mouse clicks work | Can click on username field | ☐ |
| Keyboard types | Can type characters | ☐ |
| Can enter username | Type: `obsidian` | ☐ |
| Can enter password | Type: `toor` | ☐ |
| Login successful | Desktop loads | ☐ |

### Phase 4: Desktop Environment

| Test | Expected Result | Pass/Fail |
|------|-----------------|-----------|
| XFCE desktop loads | Wallpaper visible, panels present | ☐ |
| Wallpaper displays | Forge-themed ember wallpaper | ☐ |
| Mouse works on desktop | Can move cursor, click icons | ☐ |
| Keyboard works on desktop | Can type in terminal | ☐ |
| Application menu opens | Click menu or press Super key | ☐ |
| Terminal launches | Open terminal application | ☐ |
| Can type commands | Type `whoami` → shows `obsidian` | ☐ |
| Browser launches | Obsidian Browser opens | ☐ |

### Phase 5: System Verification

| Test | Command | Expected Result | Pass/Fail |
|------|---------|-----------------|-----------|
| Check OS version | `cat /etc/os-release` | Obsidian 1.7 | ☐ |
| Check kernel | `uname -r` | 6.1.158-obsidian-obsidian | ☐ |
| Check live mount | `mount \| grep squashfs` | /run/live/... mounted | ☐ |
| Check USB devices | `lsusb` | Lists connected USB devices | ☐ |
| Check input devices | `xinput list` | Shows keyboard and mouse | ☐ |

---

## 🚨 Troubleshooting Common Issues

### Issue: "file '/OBSIDIAN/VMLINUZ' not found"

**Cause**: EFI image embedded grub.cfg has wrong paths

**Fix**:
```bash
sudo ./scripts/fix-efi-images.sh
./scripts/rebuild-iso.sh
```

Then re-burn the new ISO.

---

### Issue: Boot menu appears but selecting an option does nothing

**Cause**: Kernel path mismatch between config and ISO filesystem

**Verify**:
```bash
# Check ISO has UPPERCASE files
isoinfo -l -i Obsidian-v1.7.iso | grep OBSIDIAN

# Should show:
# /OBSIDIAN/VMLINUZ
# /OBSIDIAN/INITRD
# /OBSIDIAN/FILESYSTEM.SQUASHFS
```

---

### Issue: Keyboard/Mouse not working at login screen

**Possible Causes**:
1. USB HID drivers not loaded
2. libinput/evdev not installed
3. X11 input driver issue

**Immediate Workaround**:
- Reboot and select "Failsafe Mode" from boot menu
- Failsafe mode loads with minimal graphics drivers

**Permanent Fix** (if you can get to a terminal):
```bash
# Check what input drivers are loaded
lsmod | grep -E "hid|input"

# Should see: usbhid, hid_generic, evdev

# Check X11 input
cat /var/log/Xorg.0.log | grep -i input

# Reinstall input drivers
sudo apt install xserver-xorg-input-libinput xserver-xorg-input-evdev
```

**Fix in Build**:
```bash
# Add to rootfs/etc/initramfs-tools/modules:
echo "usbhid" >> rootfs/etc/initramfs-tools/modules
echo "hid_generic" >> rootfs/etc/initramfs-tools/modules

# Rebuild initramfs
chroot rootfs update-initramfs -u -k all

# Copy new initrd
cp rootfs/boot/initrd.img-* iso/obsidian/initrd

# Rebuild ISO
./scripts/rebuild-iso.sh
```

---

### Issue: Screen goes black after selecting boot option

**Cause**: Graphics driver incompatibility

**Fix**: Use Safe Graphics Mode
1. At boot menu, select "Safe Graphics Mode"
2. Or press TAB on the boot entry and add: `nomodeset`

---

### Issue: System boots but hangs at "Starting [service]..."

**Cause**: Service dependency issue or hardware timeout

**Fix**: Use Debug Mode
1. At boot menu, select "Debug Mode (Verbose Boot)"
2. Watch for which service hangs
3. Note the service name and report it

---

### Issue: Login works but desktop is slow/broken

**Cause**: Graphics driver or compositor issue

**Verify**:
```bash
# Check graphics driver
glxinfo | grep "OpenGL renderer"

# Check for errors
dmesg | grep -i error
```

---

## 📋 Complete Test Report Template

```
OBSIDIAN OS v1.7 - Hardware Test Report
========================================

Date: _______________
Tester: _____________

Hardware:
  - Computer: _______________
  - CPU: _______________
  - RAM: _______________
  - GPU: _______________
  - USB Port: USB 2.0 / USB 3.0 (circle one)

Boot Method:
  - Firmware: BIOS / UEFI (circle one)
  - Secure Boot: Enabled / Disabled (circle one)
  - USB Burned with: Rufus DD / dd / Other: _______

Test Results:
  [ ] Boot menu appeared
  [ ] Kernel loaded successfully
  [ ] Plymouth/boot messages shown
  [ ] Login screen appeared
  [ ] Keyboard worked at login
  [ ] Mouse worked at login
  [ ] Successfully logged in
  [ ] Desktop loaded correctly
  [ ] Applications work

Issues Encountered:
_________________________________________________
_________________________________________________
_________________________________________________

Error Messages (exact text):
_________________________________________________
_________________________________________________

Screenshots attached: Yes / No

Overall Result: PASS / FAIL
```

---

## 🔧 Quick Commands for Testing

```bash
# System info
inxi -Fxz 2>/dev/null || echo "inxi not installed"

# Check boot mode
[ -d /sys/firmware/efi ] && echo "UEFI Boot" || echo "BIOS Boot"

# Check live system
mount | grep -E "squashfs|overlay"

# List input devices
cat /proc/bus/input/devices

# Check graphics
lspci | grep -i vga

# Network
ip addr show

# USB devices
lsusb

# Disk usage
df -h

# Memory
free -h
```

---

## 📞 Reporting Issues

When reporting issues, include:

1. **Exact error message** (take a photo if needed)
2. **Hardware specs** (computer model, CPU, GPU)
3. **Boot mode** (BIOS or UEFI)
4. **USB burn method** (Rufus DD, dd, etc.)
5. **Which boot option** you selected
6. **Where it failed** (boot menu, kernel load, login, desktop)

Create an issue at: https://github.com/reapercanuk39/Obsidian/issues
