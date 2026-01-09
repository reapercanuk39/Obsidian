# Obsidian OS - Complete Documentation & Changelog

**Last Updated**: 2026-01-09  
**Current Version**: 2.1 FORTRESS  
**Repository**: https://github.com/reapercanuk39/Obsidian

---

> **📝 Logging Requirement**: All releases, version updates, feature additions, and user-facing changes **MUST** be logged in this file. For detailed development session notes and debugging logs, use [DEV-NOTES.md](./DEV-NOTES.md).

---

## Table of Contents

1. [Overview](#-overview)
2. [Download & Quick Start](#-download--quick-start)
3. [Security Features](#%EF%B8%8F-security-features)
4. [Build Instructions](#-build-instructions)
5. [Testing & Verification](#-testing--verification)
6. [Troubleshooting](#-troubleshooting)
7. [Version History](#-version-history)
8. [Technical Reference](#-technical-reference)

---

## 🔥 Overview

Obsidian OS is a **security-hardened Linux distribution** based on Debian 12 (Bookworm), designed for users who demand maximum protection without sacrificing usability.

### Key Features

| Feature | Description |
|---------|-------------|
| 🛡️ **Kernel Hardening** | 25+ sysctl settings for maximum kernel protection |
| 🔥 **Firewall** | nftables with DROP-all policy, rate limiting |
| 🚫 **Intrusion Prevention** | Fail2ban auto-bans attackers |
| 📦 **App Sandboxing** | Firejail isolates risky applications |
| 🔒 **AppArmor** | 55+ MAC profiles for application confinement |
| 🎭 **MAC Spoofing** | Automatic MAC randomization on boot |
| 🧹 **Memory Wipe** | RAM cleared on shutdown |
| 🔍 **Rootkit Detection** | rkhunter + chkrootkit included |
| 🗑️ **Secure Delete** | Full anti-forensics suite |

### System Requirements

- **Processor**: x86_64 (64-bit Intel/AMD)
- **RAM**: 2 GB minimum, 4 GB recommended
- **Storage**: 8 GB for installation
- **Boot**: BIOS or UEFI

---

## 📥 Download & Quick Start

### Latest Release: v2.1 FORTRESS

| File | Size | MD5 |
|------|------|-----|
| [Obsidian-2.1-FORTRESS.iso](https://github.com/reapercanuk39/Obsidian/releases/download/v2.1/Obsidian-2.1-FORTRESS.iso) | 1.4 GB | `9966a7565edf91e5b3a7ebbd63a2325a` |

### Download & Verify

```bash
# Download ISO
wget https://github.com/reapercanuk39/Obsidian/releases/download/v2.1/Obsidian-2.1-FORTRESS.iso

# Verify checksum
echo "9966a7565edf91e5b3a7ebbd63a2325a  Obsidian-2.1-FORTRESS.iso" | md5sum -c
```

### Create Bootable USB

**Windows (Rufus)**:
1. Download [Rufus](https://rufus.ie/)
2. Select your USB drive (8GB+)
3. Select `Obsidian-2.0-HARDENED.iso`
4. ⚠️ **IMPORTANT**: Choose **DD Image mode** when prompted
5. Click START

**Linux**:
```bash
# Replace /dev/sdX with your USB device
sudo dd if=Obsidian-2.0-HARDENED.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

### Default Credentials

| Credential | Value |
|------------|-------|
| Username | `obsidian` |
| Password | `toor` |

⚠️ **Change the default password immediately after first login!**

---

## 🛡️ Security Features

### Kernel Hardening (`/etc/sysctl.d/99-obsidian-hardening.conf`)

| Protection | Setting | Purpose |
|------------|---------|---------|
| **ASLR** | `kernel.randomize_va_space = 2` | Randomize memory layout |
| **Pointer Restriction** | `kernel.kptr_restrict = 2` | Hide kernel pointers |
| **Ptrace Scope** | `kernel.yama.ptrace_scope = 2` | Prevent debugging attacks |
| **Dmesg Restrict** | `kernel.dmesg_restrict = 1` | Restrict kernel logs |
| **SysRq Disable** | `kernel.sysrq = 0` | Disable magic keys |
| **Core Dumps** | `fs.suid_dumpable = 0` | No SUID core dumps |
| **BPF Hardening** | `net.core.bpf_jit_harden = 2` | Harden BPF JIT |
| **Perf Paranoid** | `kernel.perf_event_paranoid = 3` | Restrict perf events |

### Network Security

| Protection | Setting | Purpose |
|------------|---------|---------|
| **Reverse Path Filter** | `net.ipv4.conf.all.rp_filter = 1` | Anti-spoofing |
| **SYN Cookies** | `net.ipv4.tcp_syncookies = 1` | SYN flood protection |
| **ICMP Redirects** | Disabled | Prevent MITM |
| **Source Routing** | Disabled | Block source routing attacks |
| **Martian Logging** | Enabled | Log suspicious packets |

### Firewall (nftables)

- **Default Policy**: DROP all incoming
- **Stateful Inspection**: Only established/related allowed
- **Rate Limiting**: 100 connections/second max
- **ICMP Protection**: Rate-limited ping responses
- **Blocklist Support**: IP-based blocking capability

### Security Packages Installed

```
Core Security:
├── fail2ban              - Intrusion prevention
├── firejail              - Application sandboxing
├── apparmor              - Mandatory Access Control
├── apparmor-profiles     - Pre-built MAC profiles (55+)
├── auditd                - System auditing
├── nftables              - Modern firewall

Detection & Scanning:
├── rkhunter              - Rootkit detection
├── chkrootkit            - Rootkit detection
├── debsums               - Package integrity verification

Privacy & Anti-Forensics:
├── macchanger            - MAC address randomization
├── secure-delete         - Secure file deletion (srm, sfill, sdmem, sswap)
├── bleachbit             - System cleaner with shredding

System Hardening:
├── libpam-tmpdir         - Private /tmp directories
├── needrestart           - Service restart notifications
└── apt-listbugs          - Security bug tracking
```

### Quick Security Commands

```bash
# Sandbox Firefox
firejail firefox

# Secure delete a file
srm -vz sensitive-file.txt

# Wipe free space
sfill -v /home/user/

# Check for rootkits
sudo rkhunter --check
sudo chkrootkit

# View firewall status
sudo nft list ruleset

# View blocked IPs
sudo fail2ban-client status

# Randomize MAC address
sudo macchanger -r eth0
```

### Security Comparison

| Feature | Standard Debian | Obsidian 2.0 HARDENED |
|---------|-----------------|----------------------|
| Kernel Hardening | ❌ Default | ✅ 25+ settings |
| Firewall | ❌ Empty | ✅ DROP policy |
| Fail2ban | ❌ | ✅ Enabled |
| AppArmor Profiles | 5 | 55+ |
| Firejail | ❌ | ✅ |
| MAC Spoofing | ❌ | ✅ Automatic |
| Memory Wipe | ❌ | ✅ On shutdown |
| Rootkit Detection | ❌ | ✅ rkhunter + chkrootkit |

### Security Limitations

1. **Not Amnesic**: Unlike Tails, Obsidian persists data. Use encrypted partitions for sensitive data.
2. **No Tor by Default**: Network traffic is not anonymized. Install tor/torsocks if needed.
3. **Hardware Trust**: Cannot protect against compromised firmware/BIOS.
4. **User Responsibility**: Security tools must be used correctly.

---

## 🔧 Build Instructions

### Prerequisites

Ensure you have the required tools:
```bash
apt install xorriso mksquashfs squashfs-tools
```

### Clone Repository

```bash
git clone https://github.com/reapercanuk39/Obsidian.git
cd Obsidian
```

### Full System Rebuild

If you modify rootfs (install packages, change themes):

```bash
# 1. Make rootfs changes
chroot rootfs /bin/bash
# ... make changes ...
exit

# 2. Copy kernel/initrd to ISO
cp rootfs/boot/vmlinuz-* iso/obsidian/vmlinuz
cp rootfs/boot/initrd.img-* iso/obsidian/initrd

# 3. Rebuild squashfs
rm -f iso/obsidian/filesystem.squashfs
mksquashfs rootfs iso/obsidian/filesystem.squashfs \
    -comp zstd -Xcompression-level 15 -b 1M -processors 4 -no-duplicates

# 4. Rebuild ISO (auto-checks EFI images)
./scripts/rebuild-iso.sh
```

### Config-Only Rebuild

If you only modify boot configs:

```bash
# Edit configs (optional)
nano iso/boot/grub/grub.cfg
nano iso/isolinux/isolinux.cfg

# Rebuild ISO (auto-fixes EFI images if needed)
./scripts/rebuild-iso.sh
```

### Build Options

| Compression | Command | Build Time | ISO Size |
|-------------|---------|------------|----------|
| ZSTD (fast) | `./scripts/rebuild-iso.sh` | ~66 seconds | 1.4 GB |
| XZ (compact) | `./scripts/rebuild-iso-xz.sh` | ~8 minutes | 1.2 GB |

### Test in QEMU

```bash
# BIOS boot test
qemu-system-x86_64 -cdrom Obsidian-2.0-HARDENED.iso -m 4096 -enable-kvm

# UEFI boot test (requires OVMF)
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd \
    -cdrom Obsidian-2.0-HARDENED.iso -m 4096 -enable-kvm
```

---

## 🧪 Testing & Verification

### Pre-Burn Validation

Run before burning to USB:
```bash
sudo ./scripts/pre-burn-validation.sh
```

### Post-Burn USB Test Checklist

#### Phase 1: Boot Menu
- [ ] USB appears in BIOS boot menu
- [ ] Boot menu loads with "OBSIDIAN OS" title
- [ ] Menu is navigable with arrow keys

#### Phase 2: Kernel Loading
- [ ] Select "Start Obsidian OS"
- [ ] **NO** "file not found" error
- [ ] Boot messages or Plymouth splash visible

#### Phase 3: Login Screen
- [ ] LightDM login screen appears
- [ ] Mouse and keyboard work
- [ ] Can login with `obsidian` / `toor`

#### Phase 4: Desktop
- [ ] XFCE desktop loads
- [ ] Wallpaper visible
- [ ] Terminal opens and accepts input

### Verification Commands

```bash
# Check OS version
cat /etc/os-release

# Check kernel
uname -r

# Check boot mode
[ -d /sys/firmware/efi ] && echo "UEFI Boot" || echo "BIOS Boot"

# Check live system
mount | grep squashfs

# Check security services
sudo systemctl status fail2ban nftables apparmor
```

---

## 🔧 Troubleshooting

### Issue: "file '/OBSIDIAN/VMLINUZ' not found"

**Cause**: EFI image embedded grub.cfg has wrong paths

**Fix**:
```bash
sudo ./scripts/fix-efi-images.sh
./scripts/rebuild-iso.sh
```

Then re-burn the new ISO.

### Issue: Keyboard/Mouse not working at login

**Workaround**: Reboot and select "Failsafe Mode" from boot menu

**Permanent Fix**:
```bash
# Add USB HID modules to initramfs
echo "usbhid" >> rootfs/etc/initramfs-tools/modules
echo "hid_generic" >> rootfs/etc/initramfs-tools/modules
chroot rootfs update-initramfs -u -k all
```

### Issue: Screen goes black after boot selection

**Fix**: Use Safe Graphics Mode
1. At boot menu, select "Safe Graphics Mode"
2. Or press TAB and add: `nomodeset`

### Issue: Boot menu appears but selecting option does nothing

**Verify ISO structure**:
```bash
isoinfo -l -i Obsidian-2.0-HARDENED.iso | grep OBSIDIAN

# Should show:
# /OBSIDIAN/VMLINUZ
# /OBSIDIAN/INITRD
# /OBSIDIAN/FILESYSTEM.SQUASHFS
```

---

## 📜 Version History

### v2.1 FORTRESS (2026-01-09)

**Maximum security release** - Tier 2 hardening implementation:

#### Authentication & Access Control
- ✅ Account lockout after 5 failed attempts (15 min)
- ✅ Sudo hardening (5 min timeout, logging, noexec)
- ✅ USBGuard device whitelisting (templates included)
- ✅ GRUB password protection script
- ✅ Shell auto-logout after 15 min inactivity
- ✅ Restrictive umask (027)

#### Kernel & System Hardening
- ✅ 30+ dangerous kernel modules blacklisted (Firewire, Thunderbolt, Bluetooth, uncommon filesystems/protocols)
- ✅ Comprehensive auditd rules (CIS compliant)
- ✅ Core dump disabled
- ✅ Process limits (fork bomb protection)

#### Network Security
- ✅ DNS over TLS (Cloudflare + Quad9 fallback)
- ✅ DNSSEC validation enabled
- ✅ Multicast DNS disabled
- ✅ LLMNR disabled

#### Filesystem Security
- ✅ Secure mount options (noexec,nosuid,nodev on /tmp, /dev/shm)
- ✅ Auto-applied at boot via systemd service

#### Monitoring & Detection
- ✅ Lynis security auditing (with timer)
- ✅ AIDE file integrity monitoring
- ✅ ClamAV antivirus scanning
- ✅ Security status command: `obsidian-security-status`

**New Security Tools**:
- `obsidian-security-status` - Check security configuration
- `obsidian-aide-init` - Initialize file integrity database
- `obsidian-grub-password.sh` - Set bootloader password

**Build Details**:
- File: `Obsidian-2.1-FORTRESS.iso`
- Size: 1.4 GB
- MD5: `9966a7565edf91e5b3a7ebbd63a2325a`
- Compression: ZSTD Level 15

### v2.0 HARDENED (2026-01-08)

**Security-focused release** with comprehensive hardening:

- ✅ 25+ kernel sysctl hardening settings
- ✅ nftables firewall with DROP-all policy
- ✅ Fail2ban intrusion prevention
- ✅ AppArmor with 55+ profiles
- ✅ Firejail application sandboxing
- ✅ MAC address spoofing on boot
- ✅ Memory wipe on shutdown
- ✅ Rootkit detection (rkhunter + chkrootkit)
- ✅ Secure-delete anti-forensics suite

**Build Details**:
- File: `Obsidian-2.0-HARDENED.iso`
- Size: 1.4 GB
- MD5: `7f9ac97cd9f4bc83954f22ae829f39d8`
- Compression: ZSTD Level 15

### v1.7 (2026-01-08)

- ✅ Comprehensive 33-point system audit
- ✅ All boot paths verified UPPERCASE
- ✅ Automated EFI image fix in build script
- ✅ Fresh squashfs rebuild with v1.7 branding

### v1.6 Complete (2026-01-08)

- ✅ Plymouth minimal boot theme (pulsing diamond)
- ✅ 8 forge-themed wallpapers
- ✅ Papirus icons with ember orange folders
- ✅ Preload for faster app launches
- ✅ 292 MB size optimization
- ✅ Critical EFI boot path fixes

### v1.5 (2026-01-07)

- ✅ Initial EFI boot fix
- ✅ ZSTD compression for faster builds
- ✅ Size optimizations (kernel source removed)

### v1.0-1.4 (Earlier)

- Initial Obsidian OS builds
- Debian 12 base with XFCE
- Custom branding and themes
- Microsoft Edge rebranded as "Obsidian Browser"

---

## 📖 Technical Reference

### Boot Configuration Architecture

Obsidian OS has **4 boot configuration locations**:

| # | Location | Type | Used For |
|---|----------|------|----------|
| 1 | `iso/boot/grub/grub.cfg` | Text file | UEFI boot (direct) |
| 2 | `iso/isolinux/isolinux.cfg` | Text file | BIOS boot |
| 3 | `iso/boot/grub/efi.img` → `EFI/boot/grub.cfg` | FAT image | USB UEFI |
| 4 | `iso/efi/efi.img` → `EFI/boot/grub.cfg` | FAT image | USB UEFI fallback |

**Critical**: All paths must be **UPPERCASE** to match ISO9660 filesystem.

### ISO Structure

```
ISO Root/
├── OBSIDIAN/
│   ├── VMLINUZ              (kernel)
│   ├── INITRD               (initramfs)
│   └── FILESYSTEM.SQUASHFS  (root filesystem)
├── boot/
│   └── grub/
│       ├── grub.cfg         (UEFI config)
│       └── efi.img          (EFI partition image)
├── isolinux/
│   └── isolinux.cfg         (BIOS config)
└── efi/
    └── efi.img              (backup EFI partition)
```

### EFI Image Fix Script

If boot errors occur, use the automated fix:

```bash
sudo ./scripts/fix-efi-images.sh
./scripts/rebuild-iso.sh
```

This mounts both EFI images and updates embedded grub.cfg to use UPPERCASE paths.

### Verification Commands

```bash
# Check all 4 boot config locations
echo "=== Main GRUB ===" && cat iso/boot/grub/grub.cfg | grep "linux /OBSIDIAN"
echo "=== ISOLINUX ===" && cat iso/isolinux/isolinux.cfg | grep "KERNEL /OBSIDIAN"

# Check EFI images (requires root)
mkdir -p /tmp/check
mount -o loop iso/boot/grub/efi.img /tmp/check
echo "=== EFI Image 1 ===" && cat /tmp/check/EFI/boot/grub.cfg | grep "linux /OBSIDIAN"
umount /tmp/check
mount -o loop iso/efi/efi.img /tmp/check
echo "=== EFI Image 2 ===" && cat /tmp/check/EFI/boot/grub.cfg | grep "linux /OBSIDIAN"
umount /tmp/check && rmdir /tmp/check
```

---

## 📄 License

This project is licensed under the GPL-3.0 License - see [LICENSE](../LICENSE) for details.

Obsidian OS maintains the licenses of all included open-source components:
- Linux Kernel: GPLv2
- Debian packages: Various open-source licenses

---

## 🙏 Credits

- Based on Debian GNU/Linux
- Security research from Tails, Whonix, Kicksecure, Qubes OS
- XFCE Desktop Environment
- Papirus Icon Theme

---

**Obsidian OS** — *Security Without Compromise*

---

